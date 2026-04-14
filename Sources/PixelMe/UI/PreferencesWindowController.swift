/// Preferences window.

#if os(macOS)
import AppKit
import PixelMeCore

// MARK: - PreferencesWindowController

public final class PreferencesWindowController: NSWindowController {

    // MARK: Singleton

    public static let shared = PreferencesWindowController()

    // MARK: Stored preferences keys

    private enum Keys {
        static let tolerance        = "detectionTolerance"
        static let exportFormat     = "exportFormat"
        static let unit             = "designUnit"
        static let sketchBridgeOn   = "sketchBridgeEnabled"
        static let restoreSession   = "restoreSessionOnLaunch"
        static let exportPadding    = "exportPadding"
    }

    // MARK: Defaults

    /// The currently-selected detection tolerance.
    public static var tolerance: DetectionTolerance {
        get {
            let raw = UserDefaults.standard.integer(forKey: Keys.tolerance)
            return DetectionTolerance(rawValue: raw) ?? .medium
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: Keys.tolerance) }
    }

    /// The format used when copying a measurement to the clipboard.
    public static var exportFormat: ExportFormat {
        get {
            let raw = UserDefaults.standard.string(forKey: Keys.exportFormat) ?? ""
            return ExportFormat(rawValue: raw) ?? .plainText
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: Keys.exportFormat) }
    }

    /// The design unit (px / pt) used in export strings.
    public static var designUnit: DesignUnit {
        get {
            let raw = UserDefaults.standard.string(forKey: Keys.unit) ?? ""
            return DesignUnit(rawValue: raw) ?? .px
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: Keys.unit) }
    }

    /// Whether the Sketch zoom bridge is active.
    public static var sketchBridgeEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.sketchBridgeOn) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.sketchBridgeOn) }
    }

    /// Whether the previous session is restored on next launch.
    public static var restoreSessionOnLaunch: Bool {
        get {
            let val = UserDefaults.standard.object(forKey: Keys.restoreSession)
            return (val as? Bool) ?? true   // default ON
        }
        set { UserDefaults.standard.set(newValue, forKey: Keys.restoreSession) }
    }

    /// Padding added to screenshots, in logical points.
    public static var exportPadding: Double {
        get {
            let val = UserDefaults.standard.double(forKey: Keys.exportPadding)
            return val > 0 ? val : 20.0
        }
        set { UserDefaults.standard.set(newValue, forKey: Keys.exportPadding) }
    }

    // MARK: Init

    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 360),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "PixelMe Preferences"
        window.center()
        super.init(window: window)
        buildUI()
    }

    required init?(coder: NSCoder) { fatalError("Use PreferencesWindowController.shared") }

    // MARK: UI

    private func buildUI() {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 14
        stack.edgeInsets = NSEdgeInsets(top: 24, left: 24, bottom: 24, right: 24)

        // Tolerance
        stack.addArrangedSubview(makeSectionHeader("Detection"))
        stack.addArrangedSubview(makeLabeledPopUp(
            label: "Snap tolerance:",
            items: DetectionTolerance.allCases.map { "\($0)" },
            selected: PreferencesWindowController.tolerance.rawValue,
            action: #selector(toleranceChanged)
        ))

        // Export format
        stack.addArrangedSubview(makeSectionHeader("Export"))
        stack.addArrangedSubview(makeLabeledPopUp(
            label: "Clipboard format:",
            items: ExportFormat.allCases.map(\.rawValue),
            selected: ExportFormat.allCases.firstIndex(of: PreferencesWindowController.exportFormat) ?? 0,
            action: #selector(exportFormatChanged)
        ))
        stack.addArrangedSubview(makeLabeledPopUp(
            label: "Design unit:",
            items: ["px", "pt"],
            selected: PreferencesWindowController.designUnit == .px ? 0 : 1,
            action: #selector(unitChanged)
        ))

        // Integrations
        stack.addArrangedSubview(makeSectionHeader("Integrations"))
        let sketchToggle = NSButton(checkboxWithTitle: "Enable Sketch zoom bridge (AppleScript)",
                                    target: self, action: #selector(sketchToggleChanged))
        sketchToggle.state = PreferencesWindowController.sketchBridgeEnabled ? .on : .off
        stack.addArrangedSubview(sketchToggle)

        // Session
        stack.addArrangedSubview(makeSectionHeader("Session"))
        let restoreToggle = NSButton(checkboxWithTitle: "Restore session on launch",
                                     target: self, action: #selector(restoreSessionToggleChanged))
        restoreToggle.state = PreferencesWindowController.restoreSessionOnLaunch ? .on : .off
        stack.addArrangedSubview(restoreToggle)

        window?.contentView = stack
    }

    // MARK: UI helpers

    private func makeSectionHeader(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = .boldSystemFont(ofSize: 12)
        label.textColor = .secondaryLabelColor
        return label
    }

    private func makeLabeledPopUp(label: String, items: [String],
                                  selected: Int, action: Selector) -> NSView {
        let row = NSStackView()
        row.orientation = .horizontal
        row.spacing = 8

        let lbl = NSTextField(labelWithString: label)
        lbl.font = .systemFont(ofSize: 13)

        let popup = NSPopUpButton()
        items.forEach { popup.addItem(withTitle: $0) }
        popup.selectItem(at: selected)
        popup.target = self
        popup.action = action

        row.addArrangedSubview(lbl)
        row.addArrangedSubview(popup)
        return row
    }

    // MARK: Actions

    @objc private func toleranceChanged(_ sender: NSPopUpButton) {
        if let t = DetectionTolerance(rawValue: sender.indexOfSelectedItem) {
            PreferencesWindowController.tolerance = t
        }
    }

    @objc private func exportFormatChanged(_ sender: NSPopUpButton) {
        let formats = ExportFormat.allCases
        if sender.indexOfSelectedItem < formats.count {
            PreferencesWindowController.exportFormat = formats[sender.indexOfSelectedItem]
        }
    }

    @objc private func unitChanged(_ sender: NSPopUpButton) {
        PreferencesWindowController.designUnit = sender.indexOfSelectedItem == 0 ? .px : .pt
    }

    @objc private func sketchToggleChanged(_ sender: NSButton) {
        PreferencesWindowController.sketchBridgeEnabled = sender.state == .on
    }

    @objc private func restoreSessionToggleChanged(_ sender: NSButton) {
        PreferencesWindowController.restoreSessionOnLaunch = sender.state == .on
    }
}
#endif
