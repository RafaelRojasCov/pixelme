import XCTest
@testable import PixelMeCore

// MARK: - GuideManager tests

final class GuideManagerTests: XCTestCase {

    private var manager: GuideManager!

    override func setUp() {
        super.setUp()
        manager = GuideManager()
    }

    // MARK: Add / remove

    func testAddGuide() {
        let guide = manager.addGuide(axis: .horizontal, position: 200)
        XCTAssertEqual(manager.guides.count, 1)
        XCTAssertEqual(guide.axis, .horizontal)
        XCTAssertEqual(guide.position, 200)
    }

    func testRemoveGuide() {
        let guide = manager.addGuide(axis: .vertical, position: 100)
        manager.removeGuide(id: guide.id)
        XCTAssertTrue(manager.guides.isEmpty)
    }

    func testClearAll() {
        manager.addGuide(axis: .horizontal, position: 100)
        manager.addGuide(axis: .vertical, position: 200)
        manager.clearAll()
        XCTAssertTrue(manager.guides.isEmpty)
    }

    // MARK: Move

    func testMoveGuide() {
        let guide = manager.addGuide(axis: .horizontal, position: 100)
        manager.moveGuide(id: guide.id, to: 250)
        XCTAssertEqual(manager.guides.first?.position, 250)
    }

    // MARK: Midpoint (v2.6)

    func testAddMidpointGuide() {
        let a = manager.addGuide(axis: .horizontal, position: 100)
        let b = manager.addGuide(axis: .horizontal, position: 300)
        let mid = manager.addMidpointGuide(between: a.id, and: b.id)
        XCTAssertNotNil(mid)
        XCTAssertEqual(mid?.position, 200)
        XCTAssertEqual(manager.guides.count, 3)
    }

    func testAddMidpointGuideFailsForDifferentAxes() {
        let a = manager.addGuide(axis: .horizontal, position: 100)
        let b = manager.addGuide(axis: .vertical,   position: 300)
        let mid = manager.addMidpointGuide(between: a.id, and: b.id)
        XCTAssertNil(mid)
    }

    func testAddMidpointGuideFailsForInvalidIDs() {
        let mid = manager.addMidpointGuide(between: UUID(), and: UUID())
        XCTAssertNil(mid)
    }

    // MARK: Sorting

    func testGuidesOnAxisAreSorted() {
        manager.addGuide(axis: .horizontal, position: 300)
        manager.addGuide(axis: .horizontal, position: 100)
        manager.addGuide(axis: .horizontal, position: 200)
        let sorted = manager.guides(on: .horizontal).map(\.position)
        XCTAssertEqual(sorted, [100, 200, 300])
    }

    // MARK: Distances

    func testDistancesIncludeScreenEdgesAndGuide() {
        manager.addGuide(axis: .horizontal, position: 400)
        let dists = manager.distances(from: 600, on: .horizontal, displayExtent: 1080)
        XCTAssertEqual(dists.count, 3)   // screen min + guide + screen max
        let labels = dists.map(\.label)
        XCTAssertTrue(labels.contains("screen edge (min)"))
        XCTAssertTrue(labels.contains("screen edge (max)"))
    }
}
