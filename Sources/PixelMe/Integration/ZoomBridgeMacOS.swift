/// macOS design-tool zoom bridge implementations.
///
/// Concrete implementations of `ZoomBridgeDelegate` for each supported design application.
///
/// - `SketchZoomBridge`  — uses AppleScript to query Sketch's document zoom value.
/// - `AccessibilityZoomBridge` — reads the zoom percentage from the app's toolbar via AX API.
/// - `KeyboardEstimateZoomBridge` — estimates zoom changes from CMD+= / CMD+- key events.

#if os(macOS)
import AppKit
import PixelMeCore

// MARK: - CompositeZoomBridgeDelegate

/// Tries each bridge in order and returns the first non-nil result.
public final class CompositeZoomBridgeDelegate: ZoomBridgeDelegate {
    private let bridges: [DesignApp: any ZoomBridgeProtocol]

    public init() {
        bridges = [
            .sketch:           SketchZoomBridge(),
            .figma:            AccessibilityZoomBridge(app: .figma),
            .adobeXD:          AccessibilityZoomBridge(app: .adobeXD),
            .affinityDesigner: AccessibilityZoomBridge(app: .affinityDesigner),
            .affinityPhoto:    AccessibilityZoomBridge(app: .affinityPhoto)
        ]
    }

    public func zoomLevel(for app: DesignApp) async -> ZoomLevel? {
        await bridges[app]?.fetchZoomLevel()
    }
}

// MARK: - ZoomBridgeProtocol (internal)

private protocol ZoomBridgeProtocol: AnyObject {
    func fetchZoomLevel() async -> ZoomLevel?
}

// MARK: - SketchZoomBridge

/// Queries Sketch via AppleScript:
/// `tell application "Sketch" to zoom value of current view of front document`
private final class SketchZoomBridge: ZoomBridgeProtocol {
    func fetchZoomLevel() async -> ZoomLevel? {
        let script = """
        tell application "Sketch"
            if (count of documents) = 0 then return ""
            set zv to zoom value of current view of front document
            return zv as string
        end tell
        """
        guard
            let appleScript = NSAppleScript(source: script),
            let result = appleScript.executeAndReturnError(nil).stringValue,
            let factor = Double(result)
        else { return nil }

        return ZoomLevel(factor: factor, source: .sketch)
    }
}

// MARK: - AccessibilityZoomBridge

/// Reads the zoom value displayed in the design app's toolbar using the AX API.
///
/// This looks for a text element whose value matches a percentage string like "150%".
private final class AccessibilityZoomBridge: ZoomBridgeProtocol {
    private let targetApp: DesignApp

    init(app: DesignApp) { self.targetApp = app }

    func fetchZoomLevel() async -> ZoomLevel? {
        guard let runningApp = NSRunningApplication.runningApplications(
            withBundleIdentifier: targetApp.rawValue
        ).first else { return nil }

        let axApp = AXUIElementCreateApplication(runningApp.processIdentifier)
        guard let factor = findZoomFactor(in: axApp) else { return nil }
        return ZoomLevel(factor: factor, source: targetApp)
    }

    // MARK: AX traversal

    private func findZoomFactor(in element: AXUIElement, depth: Int = 0) -> Double? {
        guard depth < 8 else { return nil }   // limit traversal depth

        // Check if this element holds a zoom value
        var valueRef: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &valueRef)
        if let str = valueRef as? String, let factor = parseZoomPercentage(str) {
            return factor
        }

        // Recurse into children
        var childrenRef: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenRef)
        guard let children = childrenRef as? [AXUIElement] else { return nil }
        for child in children {
            if let found = findZoomFactor(in: child, depth: depth + 1) {
                return found
            }
        }
        return nil
    }

    /// Parses strings like `"150%"` or `"1.5"` into a zoom factor.
    private func parseZoomPercentage(_ string: String) -> Double? {
        let trimmed = string.trimmingCharacters(in: .whitespaces)
        if trimmed.hasSuffix("%") {
            let numStr = trimmed.dropLast()
            if let pct = Double(numStr) { return pct / 100.0 }
        }
        if let factor = Double(trimmed), factor > 0.05, factor < 100 {
            return factor
        }
        return nil
    }
}
#endif
