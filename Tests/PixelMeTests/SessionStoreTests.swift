import XCTest
@testable import PixelMeCore

// MARK: - SessionStore tests

final class SessionStoreTests: XCTestCase {

    private var tempURL: URL!
    private var store: SessionStore!

    override func setUp() {
        super.setUp()
        tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".json")
        store = SessionStore(fileURL: tempURL)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempURL)
        super.tearDown()
    }

    // MARK: Round-trip

    func testSaveAndLoadSession() throws {
        let rect = LogicalRect(x: 10, y: 20, width: 100, height: 50)
        let frozen = FrozenRect(rect: rect, zoomFactor: 1.5, label: "Header")
        let guide = Guide(axis: .horizontal, position: 300)

        let session = Session(frozenRects: [frozen], guides: [guide])
        try store.save(session)

        let loaded = store.load()
        XCTAssertEqual(loaded.frozenRects.count, 1)
        XCTAssertEqual(loaded.guides.count, 1)
        XCTAssertEqual(loaded.frozenRects.first?.rect.origin.x, 10)
        XCTAssertEqual(loaded.frozenRects.first?.zoomFactor, 1.5)
        XCTAssertEqual(loaded.frozenRects.first?.label, "Header")
        XCTAssertEqual(loaded.guides.first?.axis, .horizontal)
        XCTAssertEqual(loaded.guides.first?.position, 300)
    }

    func testLoadReturnsEmptySessionWhenFileDoesNotExist() {
        let session = store.load()
        XCTAssertTrue(session.frozenRects.isEmpty)
        XCTAssertTrue(session.guides.isEmpty)
    }

    func testClearRemovesFile() throws {
        let session = Session()
        try store.save(session)
        store.clear()
        XCTAssertFalse(FileManager.default.fileExists(atPath: tempURL.path))
    }

    func testLastSavedAtIsUpdatedOnSave() throws {
        let before = Date()
        let session = Session(lastSavedAt: Date.distantPast)
        try store.save(session)
        let loaded = store.load()
        XCTAssertGreaterThan(loaded.lastSavedAt, before)
    }
}
