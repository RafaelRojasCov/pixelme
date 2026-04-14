/// AppDelegate – manages the menu-bar item, global hotkeys, and session lifecycle.

#if os(macOS)
import AppKit
import PixelMeCore

@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Properties

    private var statusItem: NSStatusItem?
    private var overlayController: OverlayWindowController?
    private var permissionsManager: PermissionsManager?
    private var globalEventMonitors: [Any?] = []

    // Core engine components
    private let sessionStore = SessionStore()
    private let guideManager = GuideManager()
    private var frozenRects: [FrozenRect] = []

    // MARK: - applicationDidFinishLaunching

    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Prevent the app icon from appearing in the Dock
        NSApp.setActivationPolicy(.accessory)

        // Restore previous session
        restoreSession()

        // Verify permissions before activating the engine
        permissionsManager = PermissionsManager()
        let state = permissionsManager!.currentState()
        if !state.allGranted {
            showPermissionsOnboarding(missing: state.missing)
        }

        // Build the menu-bar status item
        setupMenuBar()

        // Register global keyboard shortcuts
        registerGlobalHotkeys()

        // Prepare the full-screen overlay
        overlayController = OverlayWindowController(
            guideManager: guideManager,
            frozenRects: frozenRects
        )
    }

    // MARK: - applicationWillTerminate

    public func applicationWillTerminate(_ notification: Notification) {
        saveSession()
        removeGlobalEventMonitors()
    }

    // MARK: - Menu bar setup

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        guard let button = statusItem?.button else { return }
        button.image = NSImage(systemSymbolName: "ruler", accessibilityDescription: "PixelMe")
        button.action = #selector(statusItemClicked)
        button.target = self
    }

    @objc private func statusItemClicked() {
        buildAndShowMenu()
    }

    private func buildAndShowMenu() {
        let menu = NSMenu()

        // Find Dimensions
        let findItem = NSMenuItem(
            title: "Find Dimensions",
            action: #selector(activateFindDimensions),
            keyEquivalent: "d"
        )
        findItem.keyEquivalentModifierMask = [.command, .shift]
        menu.addItem(findItem)

        // Freeze / lock current measurement
        let freezeItem = NSMenuItem(
            title: "Freeze Measurement",
            action: #selector(freezeCurrentMeasurement),
            keyEquivalent: "f"
        )
        freezeItem.keyEquivalentModifierMask = [.command, .shift]
        menu.addItem(freezeItem)

        menu.addItem(.separator())

        // Clear all frozen rects and guides
        menu.addItem(NSMenuItem(
            title: "Clear All",
            action: #selector(clearAll),
            keyEquivalent: ""
        ))

        menu.addItem(.separator())

        // Preferences
        menu.addItem(NSMenuItem(
            title: "Preferences…",
            action: #selector(openPreferences),
            keyEquivalent: ","
        ))

        menu.addItem(.separator())

        // Quit
        menu.addItem(NSMenuItem(
            title: "Quit PixelMe",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))

        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }

    // MARK: - Global hotkey registration

    private func registerGlobalHotkeys() {
        // CMD+SHIFT+F  →  Freeze current measurement
        let freezeMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: .keyDown
        ) { [weak self] event in
            guard let self else { return }
            if event.modifierFlags.contains([.command, .shift]) &&
               event.keyCode == 3 /* F */ {
                Task { @MainActor in self.freezeCurrentMeasurement() }
            }
        }
        globalEventMonitors.append(freezeMonitor)

        // ESC  →  Cancel active tool
        let escMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: .keyDown
        ) { [weak self] event in
            guard let self else { return }
            if event.keyCode == 53 /* ESC */ {
                Task { @MainActor in self.cancelActiveTool() }
            }
        }
        globalEventMonitors.append(escMonitor)
    }

    private func removeGlobalEventMonitors() {
        globalEventMonitors.forEach { monitor in
            if let m = monitor { NSEvent.removeMonitor(m) }
        }
        globalEventMonitors.removeAll()
    }

    // MARK: - Actions

    @objc private func activateFindDimensions() {
        overlayController?.activateCrosshairMode()
    }

    @objc private func freezeCurrentMeasurement() {
        overlayController?.freezeCurrentMeasurement()
    }

    @objc private func clearAll() {
        frozenRects.removeAll()
        guideManager.clearAll()
        overlayController?.clearAll()
    }

    @objc private func cancelActiveTool() {
        overlayController?.cancelActiveTool()
    }

    @objc private func openPreferences() {
        PreferencesWindowController.shared.showWindow(nil)
    }

    // MARK: - Session helpers

    private func restoreSession() {
        let session = sessionStore.load()
        frozenRects = session.frozenRects
        for guide in session.guides {
            guideManager.addGuide(axis: guide.axis, position: guide.position)
        }
    }

    private func saveSession() {
        let session = Session(
            frozenRects: frozenRects,
            guides: guideManager.guides
        )
        try? sessionStore.save(session)
    }

    // MARK: - Permissions onboarding

    private func showPermissionsOnboarding(missing: [PermissionType]) {
        PermissionsOnboardingWindowController(
            missingPermissions: missing,
            provider: permissionsManager!
        ).showWindow(nil)
    }
}

#endif
