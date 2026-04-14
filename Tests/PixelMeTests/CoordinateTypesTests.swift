import XCTest
@testable import PixelMeCore

// MARK: - Coordinate tests

final class CoordinateTypesTests: XCTestCase {

    func testScreenRelativePoint() {
        let global = LogicalPoint(x: 300, y: 200)
        let origin = LogicalPoint(x: 100, y: 50)
        let relative = screenRelativePoint(global, screenOrigin: origin)
        XCTAssertEqual(relative.x, 200)
        XCTAssertEqual(relative.y, 150)
    }

    func testLogicalPointsFromPhysicalPixels() {
        XCTAssertEqual(logicalPoints(fromPhysicalPixels: 40, backingScaleFactor: 2.0), 20)
        XCTAssertEqual(logicalPoints(fromPhysicalPixels: 30, backingScaleFactor: 1.0), 30)
    }

    func testPhysicalPixelsFromLogicalPoints() {
        XCTAssertEqual(physicalPixels(fromLogicalPoints: 20, backingScaleFactor: 2.0), 40)
    }

    func testLogicalRectContains() {
        let rect = LogicalRect(x: 10, y: 10, width: 80, height: 60)
        XCTAssertTrue(rect.contains(LogicalPoint(x: 50, y: 40)))
        XCTAssertFalse(rect.contains(LogicalPoint(x: 5, y: 40)))
    }

    func testLogicalRectExpanded() {
        let rect = LogicalRect(x: 10, y: 10, width: 80, height: 60)
        let expanded = rect.expanded(by: 10)
        XCTAssertEqual(expanded.origin.x, 0)
        XCTAssertEqual(expanded.origin.y, 0)
        XCTAssertEqual(expanded.size.width, 100)
        XCTAssertEqual(expanded.size.height, 80)
    }

    func testLogicalRectMidpoints() {
        let rect = LogicalRect(x: 0, y: 0, width: 100, height: 60)
        XCTAssertEqual(rect.midX, 50)
        XCTAssertEqual(rect.midY, 30)
    }

    func testZeroBackingScaleFactor() {
        // Should not crash or divide by zero
        XCTAssertEqual(logicalPoints(fromPhysicalPixels: 100, backingScaleFactor: 0), 100)
    }
}
