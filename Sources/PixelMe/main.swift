/// Application entry point and lifecycle management.
///
/// PixelMe runs as a "Background-only" (LSUIElement) application that lives in the
/// menu bar.  This file contains the `main` entry point, AppDelegate, and the menu
/// bar status item setup.

#if os(macOS)
import AppKit

// MARK: - Entry point

// Use NSApplicationMain only on macOS
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
#endif

