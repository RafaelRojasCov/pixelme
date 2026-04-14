import XCTest
@testable import PixelMeCore

// MARK: - ZoomBridge tests

final class ZoomBridgeTests: XCTestCase {

    // MARK: ZoomLevel

    func testZoomLevelGuardsAgainstZeroFactor() {
        let z = ZoomLevel(factor: 0, source: .sketch)
        XCTAssertGreaterThan(z.factor, 0)
    }

    func testZoomLevelDescription200Percent() {
        let z = ZoomLevel(factor: 2.0, source: .figma)
        XCTAssertTrue(z.description.hasPrefix("200%"))
    }

    // MARK: ZoomBridgeManager cache

    func testZoomBridgeManagerReturnsFallbackWhenNoDelegateSet() async {
        let manager = ZoomBridgeManager()
        let factor = await manager.zoomFactor(for: .sketch)
        XCTAssertEqual(factor, 1.0)
    }

    func testZoomBridgeManagerUsesCache() async {
        let manager = ZoomBridgeManager(cacheExpiry: 10)
        let zoom = ZoomLevel(factor: 3.0, source: .figma)
        manager.updateCache(zoom: zoom)
        let factor = await manager.zoomFactor(for: .figma)
        XCTAssertEqual(factor, 3.0, accuracy: 1e-9)
    }

    func testZoomBridgeManagerCacheExpiry() async throws {
        let manager = ZoomBridgeManager(cacheExpiry: 0.01)  // 10 ms
        let zoom = ZoomLevel(factor: 2.5, source: .adobeXD)
        manager.updateCache(zoom: zoom)
        // Wait for cache to expire
        try await Task.sleep(nanoseconds: 20_000_000)   // 20 ms
        let factor = await manager.zoomFactor(for: .adobeXD)
        // No delegate → falls back to 1.0
        XCTAssertEqual(factor, 1.0, accuracy: 1e-9)
    }
}
