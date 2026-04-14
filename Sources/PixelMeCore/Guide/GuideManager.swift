/// Guide management.
///
/// Guides are interactive alignment aids that can be pinned to the screen at specific
/// horizontal or vertical positions.  The manager tracks all active guides, computes
/// inter-guide gaps, and supports the "midpoint guide" feature introduced in v2.6.

import Foundation

// MARK: - Guide

/// A single horizontal or vertical guide at a fixed position on screen (logical points).
public struct Guide: Identifiable, Codable, Equatable {
    public let id: UUID
    /// The axis this guide is perpendicular to.
    public let axis: GuideAxis
    /// Position along the guide's primary axis (x for vertical, y for horizontal).
    public var position: Double

    public init(id: UUID = UUID(), axis: GuideAxis, position: Double) {
        self.id = id
        self.axis = axis
        self.position = position
    }
}

/// The orientation of a guide.
public enum GuideAxis: String, Codable {
    /// A vertical guide (constant x position, spans full screen height).
    case vertical
    /// A horizontal guide (constant y position, spans full screen width).
    case horizontal
}

// MARK: - GuideManager

/// Manages a collection of on-screen guides.
public final class GuideManager: Codable {
    public private(set) var guides: [Guide] = []

    public init() {}

    // MARK: Mutation

    /// Adds a new guide and returns it.
    @discardableResult
    public func addGuide(axis: GuideAxis, position: Double) -> Guide {
        let guide = Guide(axis: axis, position: position)
        guides.append(guide)
        return guide
    }

    /// Removes the guide with the given `id`.
    public func removeGuide(id: UUID) {
        guides.removeAll { $0.id == id }
    }

    /// Removes all guides.
    public func clearAll() {
        guides.removeAll()
    }

    /// Updates the position of an existing guide.
    public func moveGuide(id: UUID, to position: Double) {
        guard let idx = guides.firstIndex(where: { $0.id == id }) else { return }
        guides[idx].position = position
    }

    // MARK: Midpoint guide (v2.6)

    /// Inserts a new guide exactly halfway between two existing guides on the same axis.
    ///
    /// - Parameters:
    ///   - first: ID of the first guide.
    ///   - second: ID of the second guide.  Must share the same axis as `first`.
    /// - Returns: The newly created midpoint guide, or `nil` if either ID is invalid or
    ///   the guides are on different axes.
    @discardableResult
    public func addMidpointGuide(between firstID: UUID, and secondID: UUID) -> Guide? {
        guard
            let a = guides.first(where: { $0.id == firstID }),
            let b = guides.first(where: { $0.id == secondID }),
            a.axis == b.axis
        else { return nil }

        let midpoint = (a.position + b.position) / 2
        return addGuide(axis: a.axis, position: midpoint)
    }

    // MARK: Queries

    /// Returns all guides on the given axis, sorted by position (ascending).
    public func guides(on axis: GuideAxis) -> [Guide] {
        guides.filter { $0.axis == axis }.sorted { $0.position < $1.position }
    }

    /// Returns the distance from the given position to the nearest screen edge or guide
    /// on the specified axis.
    ///
    /// - Parameters:
    ///   - position: The query coordinate (logical points from the display origin).
    ///   - axis: The axis to query.
    ///   - displayExtent: The total width (for `.vertical`) or height (for `.horizontal`)
    ///     of the display in logical points.
    /// - Returns: An array of (label, distance) pairs describing gaps to each guide and
    ///   to the screen edges.
    public func distances(from position: Double,
                          on axis: GuideAxis,
                          displayExtent: Double) -> [(label: String, distance: Double)] {
        var positions: [Double] = [0, displayExtent]
        positions += guides(on: axis).map(\.position)
        positions.sort()

        return positions.map { p in
            let dist = abs(p - position)
            let label = p == 0 ? "screen edge (min)" :
                        p == displayExtent ? "screen edge (max)" :
                        "\(Int(p))pt guide"
            return (label, dist)
        }
    }

    // MARK: Codable

    private enum CodingKeys: String, CodingKey {
        case guides
    }
}
