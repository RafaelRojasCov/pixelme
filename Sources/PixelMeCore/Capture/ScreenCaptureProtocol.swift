/// Screen-capture abstraction layer.
///
/// Provides a protocol-based interface for obtaining a grayscale pixel buffer of the
/// current screen contents.  Two concrete implementations are available:
///
/// - `ScreenCaptureKitCapturer` — uses the modern `ScreenCaptureKit` API available
///   on macOS 12.3+.
/// - `CGWindowCapturer` — falls back to `CGWindowListCreateImage` on older OS versions.
///
/// Both implementations are defined in the macOS-specific target layer.  The protocol
/// declared here is platform-agnostic so that tests can inject mock buffers.

import Foundation

// MARK: - CaptureRegion

/// Specifies which region of the screen to capture.
public enum CaptureRegion {
    /// Capture a specific rectangle in global logical-point coordinates.
    case rect(LogicalRect)
    /// Capture the entire display that contains the given point.
    case displayContaining(LogicalPoint)
    /// Capture all displays.
    case allDisplays
}

// MARK: - CaptureRequest

/// Parameters for a single screen-capture operation.
public struct CaptureRequest {
    public let region: CaptureRegion
    /// The backing-scale factor of the target display (e.g. 2.0 for Retina).
    public let backingScaleFactor: Double
    /// Padding (in logical points) added around the requested region when exporting images.
    public var exportPadding: Double

    public init(region: CaptureRegion,
                backingScaleFactor: Double = 2.0,
                exportPadding: Double = 20.0) {
        self.region = region
        self.backingScaleFactor = backingScaleFactor
        self.exportPadding = exportPadding
    }
}

// MARK: - ScreenCapturer (protocol)

/// Implemented by platform-specific screen-capture backends.
public protocol ScreenCapturer: AnyObject {
    /// Captures the requested region and returns a grayscale buffer suitable for
    /// edge detection, along with the physical-pixel-to-logical-point scale factor.
    ///
    /// - Parameter request: Describes the region and scale.
    /// - Returns: A `GrayscaleBuffer` in physical-pixel space, plus the scale factor.
    /// - Throws: Any error from the underlying capture API.
    func captureGrayscale(_ request: CaptureRequest) async throws -> (buffer: GrayscaleBuffer,
                                                                       scaleFactor: Double)
}
