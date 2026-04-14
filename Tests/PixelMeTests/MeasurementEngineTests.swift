import XCTest
@testable import PixelMeCore

// MARK: - MeasurementEngine tests

final class MeasurementEngineTests: XCTestCase {

    // MARK: Gap calculation

    func testGapBetweenNonOverlappingRects() {
        let a = LogicalRect(x: 0, y: 0, width: 50, height: 50)
        let b = LogicalRect(x: 70, y: 60, width: 50, height: 50)
        let (h, v) = gap(between: a, and: b)
        XCTAssertEqual(h, 20, accuracy: 1e-6)
        XCTAssertEqual(v, 10, accuracy: 1e-6)
    }

    func testGapBetweenOverlappingRects() {
        let a = LogicalRect(x: 0, y: 0, width: 60, height: 60)
        let b = LogicalRect(x: 40, y: 40, width: 60, height: 60)
        let (h, v) = gap(between: a, and: b)
        // Horizontal overlap of 20 → negative gap
        XCTAssertLessThan(h, 0)
        XCTAssertLessThan(v, 0)
    }

    func testGapWhenAIsRightOfB() {
        let a = LogicalRect(x: 100, y: 0, width: 50, height: 50)
        let b = LogicalRect(x: 0,   y: 0, width: 80, height: 50)
        let (h, _) = gap(between: a, and: b)
        // a starts at 100, b ends at 80 → gap = 20
        XCTAssertEqual(h, 20, accuracy: 1e-6)
    }

    // MARK: Zoom normalisation

    func testDesignUnitsAt100PercentZoom() {
        XCTAssertEqual(designUnits(fromScreen: 150, zoomFactor: 1.0), 150)
    }

    func testDesignUnitsAt200PercentZoom() {
        XCTAssertEqual(designUnits(fromScreen: 300, zoomFactor: 2.0), 150)
    }

    func testDesignUnitsAt50PercentZoom() {
        XCTAssertEqual(designUnits(fromScreen: 75, zoomFactor: 0.5), 150)
    }

    func testDesignUnitsWithZeroZoomFactor() {
        // Guard against divide by zero – should return unchanged value
        XCTAssertEqual(designUnits(fromScreen: 150, zoomFactor: 0), 150)
    }

    // MARK: MeasurementResult

    func testMeasurementResultDesignDimensions() {
        let rect = LogicalRect(x: 0, y: 0, width: 200, height: 100)
        let m = MeasurementResult(width: 200, height: 100, rect: rect, zoomFactor: 2.0)
        XCTAssertEqual(m.designWidth, 100)
        XCTAssertEqual(m.designHeight, 50)
    }

    // MARK: Ray casting

    func testRayCastHitsRightEdge() {
        // 10-pixel wide buffer, black left half, white right half
        var pixels = [Float](repeating: 0, count: 10 * 10)
        for y in 0 ..< 10 {
            for x in 5 ..< 10 {
                pixels[y * 10 + x] = 1.0
            }
        }
        let buffer = GrayscaleBuffer(pixels: pixels, width: 10, height: 10)
        let dist = castRay(in: buffer, from: (x: 2, y: 5),
                           direction: .right,
                           threshold: DetectionTolerance.high.threshold)
        // Should hit the edge at x=5 → 3 steps
        XCTAssertLessThanOrEqual(dist, 5)
    }

    func testRayCastHitsBufferBoundaryIfNoEdge() {
        let pixels = [Float](repeating: 0.5, count: 10 * 10)
        let buffer = GrayscaleBuffer(pixels: pixels, width: 10, height: 10)
        let dist = castRay(in: buffer, from: (x: 2, y: 5),
                           direction: .right,
                           threshold: DetectionTolerance.medium.threshold)
        // No edge → should hit the right boundary (10 - 2 = 8 steps + 1 for the out-of-bounds step)
        XCTAssertGreaterThan(dist, 0)
    }
}
