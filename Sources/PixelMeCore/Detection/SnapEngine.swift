/// Magnetic snapping engine.
///
/// Given an edge map and a preliminary selection rectangle drawn by the user, the snap
/// engine adjusts each edge of the rectangle to the nearest dominant edge detected within
/// a configurable search radius.  This produces the "magnetic" feel described in the
/// PixelSnap 2 specification.

import Foundation

// MARK: - SnapResult

/// The result of applying the snapping algorithm to a preliminary rectangle.
public struct SnapResult {
    /// The snapped rectangle in physical-pixel coordinates (within the captured buffer).
    public let rect: LogicalRect
    /// Whether the left edge was snapped to a detected boundary.
    public let snappedLeft: Bool
    /// Whether the right edge was snapped to a detected boundary.
    public let snappedRight: Bool
    /// Whether the top edge was snapped to a detected boundary.
    public let snappedTop: Bool
    /// Whether the bottom edge was snapped to a detected boundary.
    public let snappedBottom: Bool
    /// Overall confidence score in [0, 1]; 1 = all four edges snapped.
    public var confidence: Double {
        let snapped = [snappedLeft, snappedRight, snappedTop, snappedBottom]
            .filter { $0 }.count
        return Double(snapped) / 4.0
    }
}

// MARK: - SnapEngine

/// Applies magnetic snapping to a preliminary user-drawn rectangle.
public struct SnapEngine {
    /// The maximum distance (in physical pixels) within which the engine looks for an edge.
    public var searchRadius: Int

    public init(searchRadius: Int = 20) {
        self.searchRadius = searchRadius
    }

    /// Snaps the edges of `preliminary` to the dominant edges found in `edgeMap`.
    ///
    /// - Parameters:
    ///   - preliminary: The rectangle the user roughly drew, in pixel coordinates
    ///     of the captured buffer.
    ///   - edgeMap: Binary edge map with the same dimensions as the captured buffer.
    /// - Returns: A `SnapResult` with adjusted edge coordinates.
    public func snap(preliminary: LogicalRect, in edgeMap: GrayscaleBuffer) -> SnapResult {
        // Convert to integer pixel coordinates for projection queries
        let left   = Int(preliminary.minX)
        let right  = Int(preliminary.maxX)
        let top    = Int(preliminary.minY)
        let bottom = Int(preliminary.maxY)

        // Row range used when projecting vertical edges (full height of selection)
        let rowStart = top
        let rowEnd   = bottom

        // Column range used when projecting horizontal edges (full width of selection)
        let colStart = left
        let colEnd   = right

        // Snap each edge independently
        let snappedLeft = dominantVerticalEdge(
            in: edgeMap,
            rowStart: rowStart, rowEnd: rowEnd,
            centreX: left, searchRadius: searchRadius
        )
        let snappedRight = dominantVerticalEdge(
            in: edgeMap,
            rowStart: rowStart, rowEnd: rowEnd,
            centreX: right, searchRadius: searchRadius
        )
        let snappedTop = dominantHorizontalEdge(
            in: edgeMap,
            colStart: colStart, colEnd: colEnd,
            centreY: top, searchRadius: searchRadius
        )
        let snappedBottom = dominantHorizontalEdge(
            in: edgeMap,
            colStart: colStart, colEnd: colEnd,
            centreY: bottom, searchRadius: searchRadius
        )

        let finalLeft   = Double(snappedLeft   ?? left)
        let finalRight  = Double(snappedRight  ?? right)
        let finalTop    = Double(snappedTop    ?? top)
        let finalBottom = Double(snappedBottom ?? bottom)

        let snappedRect = LogicalRect(
            x: finalLeft, y: finalTop,
            width: max(0, finalRight - finalLeft),
            height: max(0, finalBottom - finalTop)
        )

        return SnapResult(
            rect: snappedRect,
            snappedLeft:   snappedLeft   != nil,
            snappedRight:  snappedRight  != nil,
            snappedTop:    snappedTop    != nil,
            snappedBottom: snappedBottom != nil
        )
    }
}
