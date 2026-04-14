/// Clipboard export engine.
///
/// Converts `MeasurementResult` values into various text formats suitable for
/// pasting into design hand-off documents, CSS stylesheets, SASS files or JSON payloads.

import Foundation

// MARK: - ExportFormat

/// The supported text formats for clipboard export.
public enum ExportFormat: String, CaseIterable, Codable {
    /// Plain dimensions string, e.g. `"50 × 30"`.
    case plainText = "plain"
    /// CSS property block, e.g. `"width: 50px; height: 30px;"`.
    case css = "css"
    /// SASS variable pair, e.g. `"$width: 50px;\n$height: 30px;"`.
    case sass = "sass"
    /// JSON object, e.g. `{"width":50,"height":30,"unit":"px"}`.
    case json = "json"
}

// MARK: - Unit

/// The design unit used when exporting values.
public enum DesignUnit: String, Codable {
    case px
    case pt
}

// MARK: - ClipboardExporter

/// Formats a `MeasurementResult` as a string in the requested export format.
public struct ClipboardExporter {
    public var unit: DesignUnit

    public init(unit: DesignUnit = .px) {
        self.unit = unit
    }

    /// Returns the formatted string for `measurement` in the given `format`.
    public func format(_ measurement: MeasurementResult,
                       as exportFormat: ExportFormat) -> String {
        let w = formatValue(measurement.designWidth)
        let h = formatValue(measurement.designHeight)
        let u = unit.rawValue

        switch exportFormat {
        case .plainText:
            return "\(w) × \(h)"

        case .css:
            return "width: \(w)\(u); height: \(h)\(u);"

        case .sass:
            return "$width: \(w)\(u);\n$height: \(h)\(u);"

        case .json:
            let wRaw = roundedValue(measurement.designWidth)
            let hRaw = roundedValue(measurement.designHeight)
            return #"{"width":\#(wRaw),"height":\#(hRaw),"unit":"\#(u)"}"#
        }
    }

    // MARK: Private helpers

    /// Rounds to at most two decimal places and strips trailing zeros.
    private func formatValue(_ value: Double) -> String {
        let rounded = (value * 100).rounded() / 100
        if rounded.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(rounded))
        }
        return String(rounded)
    }

    /// Returns either an `Int` or `Double` JSON number depending on whether the value
    /// is a whole number.
    private func roundedValue(_ value: Double) -> String {
        let rounded = (value * 100).rounded() / 100
        if rounded.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(rounded))
        }
        return String(rounded)
    }
}
