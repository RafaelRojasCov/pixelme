/// Session persistence.
///
/// PixelMe v2.6 can restore the previous measurement session on launch.  This module
/// defines the `Session` data model and a `SessionStore` that serialises/deserialises
/// the session to/from a JSON file in the application support directory.

import Foundation

// MARK: - FrozenRect

/// A "frozen" (locked) measurement rectangle displayed on screen until the user removes it.
public struct FrozenRect: Identifiable, Codable, Equatable {
    public let id: UUID
    /// The measured region in logical screen points.
    public var rect: LogicalRect
    /// The zoom factor that was active when the measurement was frozen.
    public var zoomFactor: Double
    /// A user-visible label (optional).
    public var label: String?

    public init(id: UUID = UUID(),
                rect: LogicalRect,
                zoomFactor: Double = 1.0,
                label: String? = nil) {
        self.id = id
        self.rect = rect
        self.zoomFactor = zoomFactor
        self.label = label
    }
}

// MARK: - Session

/// The complete state of a PixelMe measurement session.
public struct Session: Codable {
    public var frozenRects: [FrozenRect]
    public var guides: [Guide]
    public var lastSavedAt: Date

    public init(frozenRects: [FrozenRect] = [],
                guides: [Guide] = [],
                lastSavedAt: Date = Date()) {
        self.frozenRects = frozenRects
        self.guides = guides
        self.lastSavedAt = lastSavedAt
    }
}

// MARK: - SessionStore

/// Persists and restores `Session` objects using a JSON file.
public final class SessionStore {
    private let fileURL: URL

    /// Creates a `SessionStore` that reads/writes to `fileURL`.
    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    /// Creates a `SessionStore` using the default application-support path.
    ///
    /// The file is stored at:
    /// `~/Library/Application Support/PixelMe/session.json`
    public convenience init() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!
        let dir = appSupport.appendingPathComponent("PixelMe", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir,
                                                 withIntermediateDirectories: true)
        self.init(fileURL: dir.appendingPathComponent("session.json"))
    }

    // MARK: Load

    /// Loads the persisted session.  Returns an empty session if none exists or the
    /// file cannot be decoded.
    public func load() -> Session {
        guard
            let data = try? Data(contentsOf: fileURL),
            let session = try? JSONDecoder().decode(Session.self, from: data)
        else { return Session() }
        return session
    }

    // MARK: Save

    /// Persists `session` to disk.
    ///
    /// - Throws: Any error encountered during JSON encoding or file I/O.
    public func save(_ session: Session) throws {
        var mutable = session
        mutable.lastSavedAt = Date()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(mutable)
        try data.write(to: fileURL, options: .atomic)
    }

    // MARK: Clear

    /// Deletes the persisted session file.
    public func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
