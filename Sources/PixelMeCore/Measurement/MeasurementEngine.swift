/// Distance-measurement engine.
///
/// Implements ray-casting in the four cardinal directions to find the closest
/// significant-intensity-change pixel from a given cursor position.  Also provides
/// helpers for computing the distance between two rectangles and for normalising
/// measurements through a design-tool zoom factor.

import Foundation

// MARK: - MeasurementResult

/// Represents a completed measurement between two elements on screen.
public struct MeasurementResult: Codable, CustomStringConvertible {
    /// Horizontal distance in logical points.
    public let width: Double
    /// Vertical distance in logical points.
    public let height: Double
    /// The rectangle that encloses the measured region (logical points).
    public let rect: LogicalRect
    /// Zoom factor applied when the measurement was taken (1.0 = 100 %).
    public let zoomFactor: Double

    /// Width after inverting the zoom factor to obtain real design units.
    public var designWidth: Double { width / zoomFactor }
    /// Height after inverting the zoom factor.
    public var designHeight: Double { height / zoomFactor }

    public var description: String {
        "Measurement(w:\(designWidth)pt h:\(designHeight)pt)"
    }

    public init(width: Double, height: Double,
                rect: LogicalRect, zoomFactor: Double = 1.0) {
        self.width = width
        self.height = height
        self.rect = rect
        self.zoomFactor = zoomFactor
    }
}

// MARK: - Ray-casting distance measurement

/// Casts a ray in a single cardinal direction from the given pixel coordinate until it
/// hits a pixel whose intensity gradient exceeds the supplied threshold.
///
/// - Parameters:
///   - buffer: The grayscale buffer to scan.
///   - origin: Starting coordinate (physical pixel space of the buffer).
///   - direction: The direction to cast the ray.
///   - threshold: Minimum gradient magnitude to be considered an edge.
/// - Returns: The distance in pixels to the first detected edge, or the distance to the
///   buffer boundary if no edge is found.
public func castRay(in buffer: GrayscaleBuffer,
                    from origin: (x: Int, y: Int),
                    direction: CardinalDirection,
                    threshold: Float = DetectionTolerance.medium.threshold) -> Int {
    var x = origin.x
    var y = origin.y
    var steps = 0

    while true {
        switch direction {
        case .left:  x -= 1
        case .right: x += 1
        case .up:    y -= 1
        case .down:  y += 1
        }
        steps += 1

        // Out of bounds – treat buffer edge as the edge
        if x < 0 || y < 0 || x >= buffer.width || y >= buffer.height {
            break
        }

        let g = sobelGradient(at: x, y: y, in: buffer)
        if g.magnitude >= threshold {
            break
        }
    }
    return steps
}

// MARK: - Cardinal direction

/// The four axis-aligned directions used for ray-casting.
public enum CardinalDirection: CaseIterable {
    case left, right, up, down
}

// MARK: - Gap measurement between two rectangles

/// Computes the horizontal and vertical gap between two non-overlapping rectangles.
///
/// For each axis the gap is the distance between the nearest facing edges.  A negative
/// value indicates overlap on that axis.
///
/// - Parameters:
///   - a: First rectangle (logical points).
///   - b: Second rectangle (logical points).
/// - Returns: A tuple of (horizontal gap, vertical gap).
public func gap(between a: LogicalRect, and b: LogicalRect) -> (horizontal: Double, vertical: Double) {
    let horizontal: Double
    if a.maxX <= b.minX {
        horizontal = b.minX - a.maxX
    } else if b.maxX <= a.minX {
        horizontal = a.minX - b.maxX
    } else {
        horizontal = -(min(a.maxX, b.maxX) - max(a.minX, b.minX))
    }

    let vertical: Double
    if a.maxY <= b.minY {
        vertical = b.minY - a.maxY
    } else if b.maxY <= a.minY {
        vertical = a.minY - b.maxY
    } else {
        vertical = -(min(a.maxY, b.maxY) - max(a.minY, b.minY))
    }

    return (horizontal, vertical)
}

// MARK: - Zoom-factor normalisation

/// Converts a screen measurement to real design units by dividing by the current zoom level.
///
/// Formula:  U = P / Z
///
/// - Parameters:
///   - screenMeasurement: The distance measured on screen in logical points.
///   - zoomFactor: The zoom level reported by the design application (e.g. 2.0 for 200 %).
/// - Returns: The measurement expressed in design units (px / pt).
public func designUnits(fromScreen screenMeasurement: Double,
                         zoomFactor: Double) -> Double {
    guard zoomFactor > 0 else { return screenMeasurement }
    return screenMeasurement / zoomFactor
}
