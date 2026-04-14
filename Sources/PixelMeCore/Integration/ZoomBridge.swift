/// Design-tool zoom bridge.
///
/// PixelMe must be aware of the current zoom level inside design applications so that
/// measurements can be expressed in real design units rather than screen pixels.
///
/// Each bridge implementation discovers the active zoom factor via an application-specific
/// mechanism.  The normalisation formula is:
///
///     U = P / Z
///
/// where P is the on-screen measurement and Z is the zoom factor (e.g. 2.0 for 200 %).

import Foundation

// MARK: - DesignApp

/// The design applications for which zoom bridging is supported.
public enum DesignApp: String, CaseIterable, Codable {
    case sketch     = "com.bohemiancoding.sketch3"
    case figma      = "com.figma.Desktop"
    case adobeXD    = "com.adobe.adobexd"
    case affinityDesigner = "com.seriflabs.affinitydesigner2"
    case affinityPhoto    = "com.seriflabs.affinityphoto2"
    case unknown
}

// MARK: - ZoomLevel

/// A zoom level as reported or estimated from a design application.
public struct ZoomLevel: Codable, CustomStringConvertible {
    /// Zoom factor (1.0 = 100 %, 2.0 = 200 %, etc.)
    public let factor: Double
    /// The application that reported this zoom level.
    public let source: DesignApp
    /// Whether the value was directly read (true) or estimated from keyboard events (false).
    public let isDirectlyRead: Bool

    public var description: String {
        "\(Int(factor * 100))% (\(source.rawValue)\(isDirectlyRead ? "" : " ~estimated"))"
    }

    public init(factor: Double, source: DesignApp, isDirectlyRead: Bool = true) {
        self.factor = max(0.01, factor)   // guard against divide-by-zero
        self.source = source
        self.isDirectlyRead = isDirectlyRead
    }
}

// MARK: - ZoomBridgeDelegate (platform-agnostic part)

/// Provides the current zoom level for a given running application.
///
/// Concrete implementations live in the macOS-only layer and use AppleScript (Sketch),
/// Accessibility APIs (Figma/XD), or keyboard-shortcut interception (fallback).
public protocol ZoomBridgeDelegate: AnyObject {
    /// Returns the zoom level for the specified application, or `nil` if unavailable.
    func zoomLevel(for app: DesignApp) async -> ZoomLevel?
}

// MARK: - ZoomBridgeManager

/// Manages per-application zoom bridges and caches the last known value.
public final class ZoomBridgeManager {
    public weak var delegate: ZoomBridgeDelegate?

    private var cache: [DesignApp: ZoomLevel] = [:]
    private let cacheExpiry: TimeInterval
    private var cacheTimestamps: [DesignApp: Date] = [:]

    public init(cacheExpiry: TimeInterval = 0.5, delegate: ZoomBridgeDelegate? = nil) {
        self.cacheExpiry = cacheExpiry
        self.delegate = delegate
    }

    /// Returns the best available zoom factor for `app`, using a short-lived cache to
    /// avoid hammering the accessibility API on every frame.
    public func zoomFactor(for app: DesignApp) async -> Double {
        if let cached = cachedZoom(for: app) {
            return cached.factor
        }
        if let fresh = await delegate?.zoomLevel(for: app) {
            cache[app] = fresh
            cacheTimestamps[app] = Date()
            return fresh.factor
        }
        return 1.0   // fall back to 1:1 (no zoom correction)
    }

    /// Manually updates the cached zoom (e.g. after intercepting CMD+= or CMD+-).
    public func updateCache(zoom: ZoomLevel) {
        cache[zoom.source] = zoom
        cacheTimestamps[zoom.source] = Date()
    }

    // MARK: Private

    private func cachedZoom(for app: DesignApp) -> ZoomLevel? {
        guard
            let zoom = cache[app],
            let ts   = cacheTimestamps[app],
            Date().timeIntervalSince(ts) < cacheExpiry
        else { return nil }
        return zoom
    }
}
