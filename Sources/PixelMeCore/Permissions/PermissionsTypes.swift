/// Permissions module (platform-agnostic declarations).
///
/// macOS requires explicit user consent to capture screen contents and to use the
/// Accessibility API.  This file defines the permission types and status enum used
/// across the codebase.  The concrete check/request implementations live in the
/// macOS-specific layer (PermissionsManager+macOS.swift) because they depend on
/// CoreGraphics and ApplicationServices APIs that are not available on other platforms.

import Foundation

// MARK: - PermissionType

/// The two permission categories PixelMe requires.
public enum PermissionType: String, CaseIterable {
    /// Allows reading the pixel contents of other applications' windows via
    /// `CGWindowListCreateImage` or `ScreenCaptureKit`.
    case screenRecording = "Screen Recording"
    /// Allows monitoring global keyboard events and inspecting other apps' UI element
    /// trees via the macOS Accessibility API.
    case accessibility = "Accessibility"
}

// MARK: - PermissionStatus

/// The current authorisation status for a single `PermissionType`.
public enum PermissionStatus {
    /// The user has granted the permission.
    case granted
    /// The user has not yet been prompted.
    case notDetermined
    /// The user explicitly denied the permission.
    case denied
    /// The permission is not available on this platform / OS version.
    case notAvailable
}

// MARK: - PermissionsState

/// A snapshot of the permissions state used to drive onboarding UI.
public struct PermissionsState: Equatable {
    public var screenRecording: PermissionStatus
    public var accessibility: PermissionStatus

    public init(screenRecording: PermissionStatus = .notDetermined,
                accessibility: PermissionStatus = .notDetermined) {
        self.screenRecording = screenRecording
        self.accessibility = accessibility
    }

    /// Returns `true` if all required permissions have been granted.
    public var allGranted: Bool {
        screenRecording == .granted && accessibility == .granted
    }

    /// Returns the permissions that have not yet been granted.
    public var missing: [PermissionType] {
        var result: [PermissionType] = []
        if screenRecording != .granted { result.append(.screenRecording) }
        if accessibility    != .granted { result.append(.accessibility) }
        return result
    }
}

// MARK: - PermissionsProvider (protocol)

/// Platform-specific implementations conform to this protocol so that the core logic
/// can request and observe permission changes without importing macOS frameworks.
public protocol PermissionsProvider: AnyObject {
    /// Returns the current permissions state.
    func currentState() -> PermissionsState

    /// Prompts the user to grant `permission` (opens System Settings when needed).
    func requestPermission(_ permission: PermissionType)
}
