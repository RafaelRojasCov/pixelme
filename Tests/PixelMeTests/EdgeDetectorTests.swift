import XCTest
@testable import PixelMeCore

// MARK: - Edge detector tests

final class EdgeDetectorTests: XCTestCase {

    // MARK: Helpers

    /// Creates a 5×5 flat (uniform) buffer – no edges.
    private func uniformBuffer(value: Float = 0.5) -> GrayscaleBuffer {
        GrayscaleBuffer(pixels: [Float](repeating: value, count: 25), width: 5, height: 5)
    }

    /// Creates a 5×5 buffer with a vertical edge at x = 2
    /// (left half = 0.0, right half = 1.0).
    private func verticalEdgeBuffer() -> GrayscaleBuffer {
        var pixels = [Float](repeating: 0, count: 25)
        for y in 0 ..< 5 {
            for x in 0 ..< 5 {
                pixels[y * 5 + x] = x >= 3 ? 1.0 : 0.0
            }
        }
        return GrayscaleBuffer(pixels: pixels, width: 5, height: 5)
    }

    // MARK: Sobel gradient

    func testSobelUniformImageHasZeroGradient() {
        let buffer = uniformBuffer()
        let grad = sobelGradient(at: 2, y: 2, in: buffer)
        XCTAssertEqual(grad.magnitude, 0, accuracy: 1e-6)
    }

    func testSobelVerticalEdgeHasNonZeroGradient() {
        let buffer = verticalEdgeBuffer()
        // At the boundary pixel x=2 the horizontal gradient should be significant
        let grad = sobelGradient(at: 2, y: 2, in: buffer)
        XCTAssertGreaterThan(grad.magnitude, 0)
    }

    // MARK: Edge map

    func testEdgeMapUniformImageIsAllZeros() {
        let buffer = uniformBuffer()
        let map = edgeMap(from: buffer, tolerance: .medium)
        XCTAssertTrue(map.pixels.allSatisfy { $0 == 0 })
    }

    func testEdgeMapVerticalEdgeDetected() {
        let buffer = verticalEdgeBuffer()
        let map = edgeMap(from: buffer, tolerance: .medium)
        // At least one edge pixel should be detected along the boundary column
        let hasEdge = (0 ..< 5).contains { map.pixel(x: 2, y: $0) > 0.5 ||
                                           map.pixel(x: 3, y: $0) > 0.5 }
        XCTAssertTrue(hasEdge)
    }

    // MARK: Tolerance thresholds

    func testToleranceThresholdsAreOrdered() {
        // High tolerance = lower threshold (detects more)
        XCTAssertLessThan(DetectionTolerance.high.threshold, DetectionTolerance.medium.threshold)
        XCTAssertLessThan(DetectionTolerance.medium.threshold, DetectionTolerance.low.threshold)
        XCTAssertLessThan(DetectionTolerance.low.threshold, DetectionTolerance.zero.threshold)
    }

    // MARK: Projection helpers

    func testDominantVerticalEdgeFoundInVerticalEdgeBuffer() {
        let buffer = verticalEdgeBuffer()
        let map = edgeMap(from: buffer, tolerance: .high)
        let col = dominantVerticalEdge(in: map, rowStart: 0, rowEnd: 5,
                                       centreX: 2, searchRadius: 3)
        XCTAssertNotNil(col)
    }

    func testDominantVerticalEdgeReturnsNilForUniformBuffer() {
        let buffer = uniformBuffer()
        let map = edgeMap(from: buffer, tolerance: .medium)
        let col = dominantVerticalEdge(in: map, rowStart: 0, rowEnd: 5,
                                       centreX: 2, searchRadius: 3)
        XCTAssertNil(col)
    }
}
