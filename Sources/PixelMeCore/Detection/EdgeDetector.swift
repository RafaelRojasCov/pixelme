/// Sobel-based edge detection and Canny-inspired border finding used by the snap engine.
///
/// All image data is represented as a flat array of `Float` values in the range [0, 1]
/// representing normalised grayscale intensity, stored in row-major order
/// (index = row * width + column).

import Foundation

// MARK: - Tolerance

/// Detection tolerance levels that correspond to gradient-magnitude thresholds.
public enum DetectionTolerance: Int, CaseIterable, Codable {
    /// Very aggressive – detects even subtle pixel-intensity changes (shadows, gradients).
    case high = 0
    /// Balanced – suitable for most UI screenshots.
    case medium = 1
    /// Conservative – only hard edges (high-contrast boundaries).
    case low = 2
    /// Strictest – only near-perfect black-to-white transitions.
    case zero = 3

    /// The normalised gradient magnitude threshold in the range [0, 1].
    public var threshold: Float {
        switch self {
        case .high:   return 0.05
        case .medium: return 0.15
        case .low:    return 0.30
        case .zero:   return 0.55
        }
    }
}

// MARK: - Pixel buffer helpers

/// A lightweight container for a grayscale pixel buffer.
public struct GrayscaleBuffer {
    public let pixels: [Float]   // row-major, values in [0, 1]
    public let width: Int
    public let height: Int

    public init(pixels: [Float], width: Int, height: Int) {
        precondition(pixels.count == width * height,
                     "Pixel count (\(pixels.count)) must equal width × height (\(width * height))")
        self.pixels = pixels
        self.width = width
        self.height = height
    }

    /// Safe pixel access with replicate (clamp-to-edge) padding for out-of-bounds coordinates.
    ///
    /// Replicating the border pixel avoids the "phantom edge" artefact that arises when the
    /// Sobel operator treats out-of-bounds samples as zero and thereby sees a spurious
    /// intensity jump at the edge of the buffer.
    @inline(__always)
    public func pixel(x: Int, y: Int) -> Float {
        let cx = min(max(x, 0), width - 1)
        let cy = min(max(y, 0), height - 1)
        return pixels[cy * width + cx]
    }
}

// MARK: - Sobel gradient computation

/// The result of applying the Sobel operator to a single pixel.
public struct SobelGradient {
    /// Horizontal (x-direction) gradient component.
    public let gx: Float
    /// Vertical (y-direction) gradient component.
    public let gy: Float
    /// Gradient magnitude: sqrt(gx² + gy²).
    public var magnitude: Float { (gx * gx + gy * gy).squareRoot() }
    /// Gradient direction in radians.
    public var direction: Float { atan2f(gy, gx) }
}

/// Applies the 3×3 Sobel operator at the given pixel coordinate.
///
/// The Sobel kernels used are:
/// ```
/// Kx = [-1  0  1]    Ky = [ 1  2  1]
///      [-2  0  2]         [ 0  0  0]
///      [-1  0  1]         [-1 -2 -1]
/// ```
public func sobelGradient(at x: Int, y: Int, in buffer: GrayscaleBuffer) -> SobelGradient {
    // Surrounding pixel values
    let p00 = buffer.pixel(x: x - 1, y: y - 1)
    let p10 = buffer.pixel(x: x,     y: y - 1)
    let p20 = buffer.pixel(x: x + 1, y: y - 1)
    let p01 = buffer.pixel(x: x - 1, y: y    )
    // p11 (centre) cancels in both kernels
    let p21 = buffer.pixel(x: x + 1, y: y    )
    let p02 = buffer.pixel(x: x - 1, y: y + 1)
    let p12 = buffer.pixel(x: x,     y: y + 1)
    let p22 = buffer.pixel(x: x + 1, y: y + 1)

    let gx = (-p00 + p20) + (-2 * p01 + 2 * p21) + (-p02 + p22)
    let gy = ( p00 + 2 * p10 + p20) + (-p02 - 2 * p12 - p22)

    return SobelGradient(gx: gx, gy: gy)
}

// MARK: - Edge map

/// Produces a full gradient-magnitude map for a grayscale buffer.
///
/// - Parameters:
///   - buffer: The source grayscale image.
///   - tolerance: Determines the threshold below which gradients are suppressed.
/// - Returns: A `GrayscaleBuffer` whose pixel values are 1 where an edge was detected,
///   and 0 elsewhere.
public func edgeMap(from buffer: GrayscaleBuffer,
                    tolerance: DetectionTolerance = .medium) -> GrayscaleBuffer {
    let threshold = tolerance.threshold
    var result = [Float](repeating: 0, count: buffer.width * buffer.height)
    for y in 0 ..< buffer.height {
        for x in 0 ..< buffer.width {
            let g = sobelGradient(at: x, y: y, in: buffer)
            result[y * buffer.width + x] = g.magnitude >= threshold ? 1 : 0
        }
    }
    return GrayscaleBuffer(pixels: result, width: buffer.width, height: buffer.height)
}

// MARK: - Row / column projection for snapping

/// Projects an edge map along the x-axis, returning the x-coordinate with the highest
/// edge density within the vertical slice `[rowStart, rowEnd)`.
///
/// Used by the snapping engine to locate the dominant vertical edge near a selection boundary.
///
/// - Parameters:
///   - edgeMap: A binary edge map produced by `edgeMap(from:tolerance:)`.
///   - rowStart: Inclusive start row of the region to scan.
///   - rowEnd: Exclusive end row of the region to scan.
///   - searchRadius: How many columns to examine on each side of `centreX`.
///   - centreX: The column around which to search.
/// - Returns: The column index with the most edge pixels, or `nil` if no edges are found.
public func dominantVerticalEdge(in edgeMap: GrayscaleBuffer,
                                 rowStart: Int, rowEnd: Int,
                                 centreX: Int, searchRadius: Int) -> Int? {
    let xMin = max(0, centreX - searchRadius)
    let xMax = min(edgeMap.width - 1, centreX + searchRadius)
    guard xMin <= xMax else { return nil }

    var bestX = xMin
    var bestCount = 0
    for x in xMin ... xMax {
        var count = 0
        for y in max(0, rowStart) ..< min(edgeMap.height, rowEnd) {
            if edgeMap.pixel(x: x, y: y) > 0.5 {
                count += 1
            }
        }
        if count > bestCount {
            bestCount = count
            bestX = x
        }
    }
    return bestCount > 0 ? bestX : nil
}

/// Projects an edge map along the y-axis, returning the y-coordinate with the highest
/// edge density within the horizontal slice `[colStart, colEnd)`.
public func dominantHorizontalEdge(in edgeMap: GrayscaleBuffer,
                                   colStart: Int, colEnd: Int,
                                   centreY: Int, searchRadius: Int) -> Int? {
    let yMin = max(0, centreY - searchRadius)
    let yMax = min(edgeMap.height - 1, centreY + searchRadius)
    guard yMin <= yMax else { return nil }

    var bestY = yMin
    var bestCount = 0
    for y in yMin ... yMax {
        var count = 0
        for x in max(0, colStart) ..< min(edgeMap.width, colEnd) {
            if edgeMap.pixel(x: x, y: y) > 0.5 {
                count += 1
            }
        }
        if count > bestCount {
            bestCount = count
            bestY = y
        }
    }
    return bestCount > 0 ? bestY : nil
}
