/// Core geometric types used throughout PixelMe.
///
/// macOS uses a "logical point" coordinate system that maps to a grid of physical pixels.
/// On Retina (HiDPI) displays the backing scale factor is typically 2×, meaning every
/// logical point corresponds to a 2×2 block of physical pixels.  All public APIs accept
/// and return *logical* coordinates unless explicitly stated otherwise.

import Foundation

// MARK: - Point

/// A two-dimensional point expressed in logical screen coordinates.
public struct LogicalPoint: Hashable, Codable, CustomStringConvertible {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    public var description: String { "(\(x), \(y))" }
}

// MARK: - Size

/// A width/height pair in logical screen units.
public struct LogicalSize: Hashable, Codable, CustomStringConvertible {
    public var width: Double
    public var height: Double

    public init(width: Double, height: Double) {
        self.width = width
        self.height = height
    }

    public var description: String { "\(width) × \(height)" }
}

// MARK: - Rect

/// An axis-aligned rectangle in logical screen coordinates.
public struct LogicalRect: Hashable, Codable, CustomStringConvertible {
    public var origin: LogicalPoint
    public var size: LogicalSize

    public init(origin: LogicalPoint, size: LogicalSize) {
        self.origin = origin
        self.size = size
    }

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.origin = LogicalPoint(x: x, y: y)
        self.size = LogicalSize(width: width, height: height)
    }

    public var minX: Double { origin.x }
    public var minY: Double { origin.y }
    public var maxX: Double { origin.x + size.width }
    public var maxY: Double { origin.y + size.height }
    public var midX: Double { origin.x + size.width / 2 }
    public var midY: Double { origin.y + size.height / 2 }

    public var description: String {
        "LogicalRect(x:\(origin.x) y:\(origin.y) w:\(size.width) h:\(size.height))"
    }

    /// Returns `true` if the given point lies within the rectangle.
    public func contains(_ point: LogicalPoint) -> Bool {
        point.x >= minX && point.x <= maxX &&
        point.y >= minY && point.y <= maxY
    }

    /// Returns the rectangle inset by `dx` and `dy` on each side.
    public func insetBy(dx: Double, dy: Double) -> LogicalRect {
        LogicalRect(
            x: origin.x + dx, y: origin.y + dy,
            width: max(0, size.width - dx * 2),
            height: max(0, size.height - dy * 2)
        )
    }

    /// Expands the rectangle by `amount` on every side (padding).
    public func expanded(by amount: Double) -> LogicalRect {
        insetBy(dx: -amount, dy: -amount)
    }
}

// MARK: - Screen coordinate helpers

/// Converts a global screen coordinate to a coordinate relative to a specific screen origin.
///
/// - Parameters:
///   - globalPoint: A point in the macOS global coordinate space.
///   - screenOrigin: The origin of the target screen as returned by `NSScreen.frame.origin`.
/// - Returns: The point expressed relative to the screen's own coordinate system.
public func screenRelativePoint(_ globalPoint: LogicalPoint,
                                screenOrigin: LogicalPoint) -> LogicalPoint {
    LogicalPoint(
        x: globalPoint.x - screenOrigin.x,
        y: globalPoint.y - screenOrigin.y
    )
}

/// Converts a physical-pixel measurement to logical points given a backing-scale factor.
///
/// - Parameters:
///   - physicalPixels: Distance measured in raw physical pixels.
///   - backingScaleFactor: The display's backing-scale factor (e.g. `2.0` for Retina).
/// - Returns: The equivalent distance in logical points.
public func logicalPoints(fromPhysicalPixels physicalPixels: Double,
                          backingScaleFactor: Double) -> Double {
    guard backingScaleFactor > 0 else { return physicalPixels }
    return physicalPixels / backingScaleFactor
}

/// Converts a logical-point measurement to physical pixels given a backing-scale factor.
///
/// - Parameters:
///   - logicalPoints: Distance in logical screen points.
///   - backingScaleFactor: The display's backing-scale factor.
/// - Returns: The equivalent distance in physical pixels.
public func physicalPixels(fromLogicalPoints logicalPoints: Double,
                           backingScaleFactor: Double) -> Double {
    logicalPoints * backingScaleFactor
}
