import XCTest
@testable import PixelMeCore

// MARK: - ClipboardExporter tests

final class ClipboardExporterTests: XCTestCase {

    private func makeMeasurement(width: Double = 50, height: Double = 30,
                                 zoom: Double = 1.0) -> MeasurementResult {
        MeasurementResult(
            width: width, height: height,
            rect: LogicalRect(x: 0, y: 0, width: width, height: height),
            zoomFactor: zoom
        )
    }

    // MARK: Plain text

    func testPlainTextFormat() {
        let exporter = ClipboardExporter(unit: .px)
        let result = exporter.format(makeMeasurement(), as: .plainText)
        XCTAssertEqual(result, "50 × 30")
    }

    func testPlainTextFormatWithZoom() {
        let exporter = ClipboardExporter(unit: .px)
        // Zoom 2.0 → design size is 25 × 15
        let result = exporter.format(makeMeasurement(zoom: 2.0), as: .plainText)
        XCTAssertEqual(result, "25 × 15")
    }

    // MARK: CSS

    func testCSSFormat() {
        let exporter = ClipboardExporter(unit: .px)
        let result = exporter.format(makeMeasurement(), as: .css)
        XCTAssertEqual(result, "width: 50px; height: 30px;")
    }

    func testCSSFormatWithPtUnit() {
        let exporter = ClipboardExporter(unit: .pt)
        let result = exporter.format(makeMeasurement(), as: .css)
        XCTAssertEqual(result, "width: 50pt; height: 30pt;")
    }

    // MARK: SASS

    func testSASSFormat() {
        let exporter = ClipboardExporter(unit: .px)
        let result = exporter.format(makeMeasurement(), as: .sass)
        XCTAssertEqual(result, "$width: 50px;\n$height: 30px;")
    }

    // MARK: JSON

    func testJSONFormat() {
        let exporter = ClipboardExporter(unit: .px)
        let result = exporter.format(makeMeasurement(), as: .json)
        XCTAssertEqual(result, #"{"width":50,"height":30,"unit":"px"}"#)
    }

    func testJSONFormatDecimalValues() {
        let exporter = ClipboardExporter(unit: .px)
        // zoom = 3 → 50/3 ≈ 16.67
        let result = exporter.format(makeMeasurement(width: 50, height: 30, zoom: 3.0), as: .json)
        XCTAssertTrue(result.contains("\"unit\":\"px\""))
        XCTAssertTrue(result.contains("\"width\""))
        XCTAssertTrue(result.contains("\"height\""))
    }

    // MARK: All formats compile and return non-empty

    func testAllFormatsReturnNonEmpty() {
        let exporter = ClipboardExporter()
        let m = makeMeasurement()
        for fmt in ExportFormat.allCases {
            XCTAssertFalse(exporter.format(m, as: fmt).isEmpty, "Format \(fmt) returned empty string")
        }
    }
}
