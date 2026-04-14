/// macOS permissions manager.
///
/// Checks and requests Screen Recording and Accessibility permissions using
/// CoreGraphics and ApplicationServices APIs.

#if os(macOS)
import AppKit
import CoreGraphics
import PixelMeCore

// MARK: - PermissionsManager (macOS implementation)

public final class PermissionsManager: PermissionsProvider {

    // MARK: PermissionsProvider

    public func currentState() -> PermissionsState {
        PermissionsState(
            screenRecording: screenRecordingStatus(),
            accessibility: accessibilityStatus()
        )
    }

    public func requestPermission(_ permission: PermissionType) {
        switch permission {
        case .screenRecording:
            requestScreenRecording()
        case .accessibility:
            requestAccessibility()
        }
    }

    // MARK: Screen Recording

    private func screenRecordingStatus() -> PermissionStatus {
        if CGPreflightScreenCaptureAccess() {
            return .granted
        }
        // On macOS < 10.15 the API does not exist but this code only targets macOS 13+
        return .denied
    }

    private func requestScreenRecording() {
        // Triggers the system permission dialog; the user may need to restart the app.
        CGRequestScreenCaptureAccess()
        // Also open System Settings for clarity
        openSystemSettingsPane(for: .screenRecording)
    }

    // MARK: Accessibility

    private func accessibilityStatus() -> PermissionStatus {
        let trusted = AXIsProcessTrustedWithOptions(
            [kAXTrustedCheckOptionPrompt: false] as CFDictionary
        )
        return trusted ? .granted : .denied
    }

    private func requestAccessibility() {
        // Prompt the user via Accessibility API + open System Settings
        _ = AXIsProcessTrustedWithOptions(
            [kAXTrustedCheckOptionPrompt: true] as CFDictionary
        )
        openSystemSettingsPane(for: .accessibility)
    }

    // MARK: Helpers

    private enum SettingsPane {
        case screenRecording, accessibility
    }

    private func openSystemSettingsPane(for pane: SettingsPane) {
        let urlString: String
        switch pane {
        case .screenRecording:
            urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
        case .accessibility:
            urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        }
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
}
#endif
