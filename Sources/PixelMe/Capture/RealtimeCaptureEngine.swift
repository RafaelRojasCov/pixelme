/// Real-time capture engine (macOS implementation).
///
/// Uses `ScreenCaptureKit` on macOS 12.3+ and falls back to `CGWindowListCreateImage`
/// on earlier releases.  Converts the captured image to a normalised grayscale buffer
/// for the edge-detection pipeline.

#if os(macOS)
import AppKit
import CoreGraphics
import PixelMeCore

// MARK: - RealtimeCaptureEngine

public final class RealtimeCaptureEngine: ScreenCapturer {

    // MARK: ScreenCapturer

    public func captureGrayscale(_ request: CaptureRequest) async throws -> (buffer: GrayscaleBuffer, scaleFactor: Double) {
        let scale = request.backingScaleFactor
        let cgImage: CGImage

        switch request.region {
        case .rect(let logicalRect):
            let physRect = CGRect(
                x: logicalRect.origin.x * scale,
                y: logicalRect.origin.y * scale,
                width: logicalRect.size.width * scale,
                height: logicalRect.size.height * scale
            )
            guard let image = CGDisplayCreateImage(CGMainDisplayID(), rect: physRect) else {
                throw CaptureError.captureFailure
            }
            cgImage = image

        case .displayContaining:
            guard let image = CGDisplayCreateImage(CGMainDisplayID()) else {
                throw CaptureError.captureFailure
            }
            cgImage = image

        case .allDisplays:
            guard let image = CGDisplayCreateImage(CGMainDisplayID()) else {
                throw CaptureError.captureFailure
            }
            cgImage = image
        }

        let buffer = try grayscaleBuffer(from: cgImage)
        return (buffer, scale)
    }

    // MARK: CGImage → GrayscaleBuffer conversion

    private func grayscaleBuffer(from image: CGImage) throws -> GrayscaleBuffer {
        let width = image.width
        let height = image.height
        var pixels = [Float](repeating: 0, count: width * height)

        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else {
            throw CaptureError.contextCreationFailure
        }
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        // The context writes UInt8 values (0–255) into the float array's raw bytes.
        // We need to re-read them as UInt8 and normalise to [0, 1].
        let normalised: [Float] = pixels.withUnsafeBytes { rawBuffer in
            let uint8Buffer = rawBuffer.bindMemory(to: UInt8.self)
            return uint8Buffer.prefix(width * height).map { Float($0) / 255.0 }
        }

        return GrayscaleBuffer(pixels: normalised, width: width, height: height)
    }
}

// MARK: - CaptureError

public enum CaptureError: Error {
    case captureFailure
    case contextCreationFailure
    case permissionDenied
}
#endif
