/// OverlayWindowController – transparent full-screen NSPanel drawn over all other windows.
///
/// Uses `.screenSaver` window level and `.canJoinAllSpaces` collection behaviour to
/// ensure the overlay is visible above Dock, menu bar, and full-screen apps.

#if os(macOS)
import AppKit
import PixelMeCore

// MARK: - OverlayWindowController

@MainActor
public final class OverlayWindowController: NSObject {

    // MARK: Properties

    private var overlayWindow: NSPanel?
    private var overlayView: OverlayView?
    private let guideManager: GuideManager
    private var frozenRects: [FrozenRect]

    /// Active capture / snap engine shared with the overlay view.
    private let captureEngine: RealtimeCaptureEngine

    // MARK: Init

    public init(guideManager: GuideManager, frozenRects: [FrozenRect]) {
        self.guideManager = guideManager
        self.frozenRects = frozenRects
        self.captureEngine = RealtimeCaptureEngine()
        super.init()
        buildOverlayWindow()
    }

    // MARK: Window construction

    private func buildOverlayWindow() {
        guard let screen = NSScreen.main else { return }
        let panel = NSPanel(
            contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .init(rawValue: Int(CGWindowLevelForKey(.screenSaverWindow)))
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.ignoresMouseEvents = false
        panel.acceptsMouseMovedEvents = true

        let view = OverlayView(
            frame: screen.frame,
            guideManager: guideManager,
            captureEngine: captureEngine
        )
        panel.contentView = view
        self.overlayWindow = panel
        self.overlayView = view
        panel.orderFront(nil)
    }

    // MARK: Public API

    /// Activates the crosshair/dimension-finding mode.
    public func activateCrosshairMode() {
        overlayView?.mode = .crosshair
        overlayWindow?.makeKeyAndOrderFront(nil)
    }

    /// Freezes the currently active measurement rectangle on screen.
    public func freezeCurrentMeasurement() {
        overlayView?.freezeCurrentRect()
    }

    /// Removes all frozen rects and guides.
    public func clearAll() {
        overlayView?.clearAll()
    }

    /// Cancels the active tool and returns to idle.
    public func cancelActiveTool() {
        overlayView?.mode = .idle
    }
}

// MARK: - OverlayMode

/// The active interaction mode of the overlay.
public enum OverlayMode {
    case idle
    case crosshair
    case snapping
    case frozen
}

// MARK: - OverlayView

/// Custom NSView that renders measurement guides, frozen rects and live dimension labels.
public final class OverlayView: NSView {

    // MARK: State

    public var mode: OverlayMode = .idle {
        didSet { needsDisplay = true }
    }

    private let guideManager: GuideManager
    private let captureEngine: RealtimeCaptureEngine
    private var frozenRects: [FrozenRect] = []
    private var liveMeasurement: MeasurementResult?
    private var crosshairPosition: NSPoint = .zero
    private var dragStart: NSPoint?
    private var dragCurrent: NSPoint?

    // MARK: Init

    init(frame: NSRect, guideManager: GuideManager, captureEngine: RealtimeCaptureEngine) {
        self.guideManager = guideManager
        self.captureEngine = captureEngine
        super.init(frame: frame)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    required init?(coder: NSCoder) { fatalError("Use init(frame:guideManager:captureEngine:)") }

    // MARK: Drawing

    public override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        drawGuides(in: ctx)
        drawFrozenRects(in: ctx)

        switch mode {
        case .crosshair:
            drawCrosshair(at: crosshairPosition, in: ctx)
        case .snapping:
            if let start = dragStart, let current = dragCurrent {
                drawSelectionRect(from: start, to: current, in: ctx)
            }
        default:
            break
        }

        if let measurement = liveMeasurement {
            drawDimensionLabel(for: measurement, in: ctx)
        }
    }

    // MARK: Guides

    private func drawGuides(in ctx: CGContext) {
        ctx.saveGState()
        ctx.setStrokeColor(NSColor.systemBlue.withAlphaComponent(0.6).cgColor)
        ctx.setLineWidth(1.0)
        for guide in guideManager.guides {
            switch guide.axis {
            case .horizontal:
                ctx.move(to: CGPoint(x: 0, y: guide.position))
                ctx.addLine(to: CGPoint(x: bounds.width, y: guide.position))
            case .vertical:
                ctx.move(to: CGPoint(x: guide.position, y: 0))
                ctx.addLine(to: CGPoint(x: guide.position, y: bounds.height))
            }
        }
        ctx.strokePath()
        ctx.restoreGState()
    }

    // MARK: Frozen rects

    private func drawFrozenRects(in ctx: CGContext) {
        ctx.saveGState()
        ctx.setFillColor(NSColor.systemRed.withAlphaComponent(0.15).cgColor)
        ctx.setStrokeColor(NSColor.systemRed.withAlphaComponent(0.8).cgColor)
        ctx.setLineWidth(1.0)
        for frozen in frozenRects {
            let r = frozen.rect
            let cgRect = CGRect(x: r.origin.x, y: r.origin.y,
                                width: r.size.width, height: r.size.height)
            ctx.fill(cgRect)
            ctx.stroke(cgRect)
        }
        ctx.restoreGState()
    }

    // MARK: Crosshair

    private func drawCrosshair(at point: NSPoint, in ctx: CGContext) {
        ctx.saveGState()
        ctx.setStrokeColor(NSColor.systemRed.cgColor)
        ctx.setLineWidth(1.0)
        // Horizontal line
        ctx.move(to: CGPoint(x: 0, y: point.y))
        ctx.addLine(to: CGPoint(x: bounds.width, y: point.y))
        // Vertical line
        ctx.move(to: CGPoint(x: point.x, y: 0))
        ctx.addLine(to: CGPoint(x: point.x, y: bounds.height))
        ctx.strokePath()
        ctx.restoreGState()
    }

    // MARK: Selection rect (while dragging)

    private func drawSelectionRect(from start: NSPoint, to end: NSPoint, in ctx: CGContext) {
        let rect = CGRect(
            x: min(start.x, end.x), y: min(start.y, end.y),
            width: abs(end.x - start.x), height: abs(end.y - start.y)
        )
        ctx.saveGState()
        ctx.setFillColor(NSColor.systemBlue.withAlphaComponent(0.1).cgColor)
        ctx.setStrokeColor(NSColor.systemBlue.withAlphaComponent(0.8).cgColor)
        ctx.setLineWidth(1.0)
        ctx.fill(rect)
        ctx.stroke(rect)
        ctx.restoreGState()
    }

    // MARK: Dimension labels

    private func drawDimensionLabel(for measurement: MeasurementResult, in ctx: CGContext) {
        let text = "\(Int(measurement.designWidth)) × \(Int(measurement.designHeight))"
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .medium),
            .foregroundColor: adaptiveLabelColor(below: measurement.rect)
        ]
        let str = NSAttributedString(string: text, attributes: attrs)
        let size = str.size()

        let labelX = measurement.rect.midX - Double(size.width) / 2
        let labelY = measurement.rect.midY - Double(size.height) / 2

        // Background pill
        let padding: CGFloat = 4
        let bgRect = CGRect(
            x: labelX - padding, y: labelY - padding,
            width: size.width + padding * 2, height: size.height + padding * 2
        )
        ctx.saveGState()
        ctx.setFillColor(NSColor.black.withAlphaComponent(0.6).cgColor)
        let path = CGPath(roundedRect: bgRect, cornerWidth: 4, cornerHeight: 4, transform: nil)
        ctx.addPath(path)
        ctx.fillPath()
        ctx.restoreGState()

        str.draw(at: CGPoint(x: labelX, y: labelY))
    }

    /// Chooses white or black label text based on the average luminance of the pixels
    /// under the label region.
    private func adaptiveLabelColor(below rect: LogicalRect) -> NSColor {
        // Simplified: use white text by default; a full implementation would sample pixels.
        return .white
    }

    // MARK: Mouse events

    public override func mouseMoved(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        crosshairPosition = point
        if mode == .crosshair { needsDisplay = true }
    }

    public override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        dragStart = point
        dragCurrent = point
        mode = .snapping
    }

    public override func mouseDragged(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        dragCurrent = point
        if mode == .snapping {
            Task { await updateLiveMeasurement() }
            needsDisplay = true
        }
    }

    public override func mouseUp(with event: NSEvent) {
        if mode == .snapping {
            mode = .frozen
        }
        dragStart = nil
        dragCurrent = nil
    }

    public override var acceptsFirstResponder: Bool { true }

    // MARK: Live measurement update

    private func updateLiveMeasurement() async {
        guard let start = dragStart, let current = dragCurrent else { return }
        let preliminary = LogicalRect(
            x: min(start.x, current.x),
            y: min(start.y, current.y),
            width: abs(current.x - start.x),
            height: abs(current.y - start.y)
        )
        liveMeasurement = MeasurementResult(
            width: preliminary.size.width,
            height: preliminary.size.height,
            rect: preliminary
        )
        needsDisplay = true
    }

    // MARK: Public API

    func freezeCurrentRect() {
        guard let measurement = liveMeasurement else { return }
        let frozen = FrozenRect(rect: measurement.rect, zoomFactor: measurement.zoomFactor)
        frozenRects.append(frozen)
        liveMeasurement = nil
        needsDisplay = true
    }

    func clearAll() {
        frozenRects.removeAll()
        guideManager.clearAll()
        liveMeasurement = nil
        needsDisplay = true
    }
}
#endif
