import XCTest
@testable import PixelMeCore

// MARK: - SnapEngine tests

final class SnapEngineTests: XCTestCase {

    /// A 20×20 buffer with a rectangular object (value 1.0) centred at (5,5)–(15,15),
    /// surrounded by dark background (0.0).
    private func rectBuffer() -> GrayscaleBuffer {
        var pixels = [Float](repeating: 0, count: 20 * 20)
        for y in 5 ..< 15 {
            for x in 5 ..< 15 {
                pixels[y * 20 + x] = 1.0
            }
        }
        return GrayscaleBuffer(pixels: pixels, width: 20, height: 20)
    }

    func testSnapEngineSnapsToObjectBoundary() {
        let buffer = rectBuffer()
        let map = edgeMap(from: buffer, tolerance: .high)
        let engine = SnapEngine(searchRadius: 4)

        // Preliminary rect slightly off from the true boundary
        let preliminary = LogicalRect(x: 6, y: 6, width: 8, height: 8)
        let result = engine.snap(preliminary: preliminary, in: map)

        // The snapped rect should be at least partially snapped
        XCTAssertGreaterThan(result.confidence, 0)
    }

    func testSnapEngineOnUniformBufferReturnsOriginalBounds() {
        let pixels = [Float](repeating: 0.5, count: 20 * 20)
        let buffer = GrayscaleBuffer(pixels: pixels, width: 20, height: 20)
        let map = edgeMap(from: buffer, tolerance: .medium)
        let engine = SnapEngine(searchRadius: 4)

        let preliminary = LogicalRect(x: 2, y: 2, width: 10, height: 10)
        let result = engine.snap(preliminary: preliminary, in: map)

        // Confidence should be 0 for a completely uniform image
        XCTAssertEqual(result.confidence, 0)
        XCTAssertFalse(result.snappedLeft)
        XCTAssertFalse(result.snappedRight)
        XCTAssertFalse(result.snappedTop)
        XCTAssertFalse(result.snappedBottom)
    }
}
