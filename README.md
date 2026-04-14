# PixelMe

A macOS menu-bar utility for pixel-perfect measurement on screen, inspired by the functional specification of PixelSnap 2. PixelMe lets designers and developers measure distances between any two elements on screen with sub-pixel accuracy, even across different applications.

## Features

| Feature | Description |
|---|---|
| **Find Dimensions** | Activate with `⌘⇧D` – a crosshair cursor shows live width × height |
| **Magnetic snapping** | Draw a selection rectangle and it snaps to the nearest object boundary |
| **Freeze measurement** | `⌘⇧F` locks a translucent red overlay rectangle on screen |
| **Guides** | Add horizontal/vertical guides; v2.6+ midpoint guide between two existing guides |
| **Retina / HiDPI** | All coordinates are logical points; backing-scale factor is applied automatically |
| **Design-tool zoom** | Bridges for Sketch (AppleScript), Figma, Adobe XD, Affinity (Accessibility API) |
| **Clipboard export** | Copy measurements as plain text, CSS, SASS or JSON |
| **Session restore** | Frozen rects and guides persist across app restarts |
| **Dark Mode** | Dynamic contrast labels adapt to the pixel luminance underneath |

## Architecture

```
PixelMe (macOS executable)
├── AppDelegate           – Menu bar, global hotkeys, session lifecycle
├── Overlay/
│   └── OverlayWindowController – NSPanel at .screenSaver level; renders guides,
│                                  frozen rects and live dimension labels
├── Capture/
│   └── RealtimeCaptureEngine   – CGDisplayCreateImage → grayscale buffer
├── Integration/
│   └── ZoomBridgeMacOS         – Per-app zoom level bridges (Sketch/Figma/XD/Affinity)
├── Permissions/
│   ├── PermissionsManager      – CGPreflightScreenCaptureAccess + AXIsProcessTrusted
│   └── PermissionsOnboardingWindowController
└── UI/
    └── PreferencesWindowController – UserDefaults-backed preferences

PixelMeCore (cross-platform library, testable on Linux)
├── Geometry/
│   └── CoordinateTypes         – LogicalPoint, LogicalRect, Retina helpers
├── Detection/
│   ├── EdgeDetector            – Sobel gradient, edge map, projection helpers
│   └── SnapEngine              – Magnetic snapping using edge-density projection
├── Measurement/
│   └── MeasurementEngine       – Ray-casting, gap calculation, zoom normalisation
├── Export/
│   └── ClipboardExporter       – Plain text / CSS / SASS / JSON formatters
├── Guide/
│   ├── GuideManager            – Add/remove/midpoint guides
│   └── SessionStore            – JSON persistence for frozen rects and guides
├── Integration/
│   └── ZoomBridge              – Protocol + manager (platform-agnostic)
├── Permissions/
│   └── PermissionsTypes        – Permission type / status enums
└── Capture/
    └── ScreenCaptureProtocol   – ScreenCapturer protocol for testable injection
```

## Requirements

- **macOS 13 (Ventura)** or later
- Xcode 15+ / Swift 5.9+
- Screen Recording permission (System Settings → Privacy & Security)
- Accessibility permission (System Settings → Privacy & Security)

## Building

```bash
# Build the macOS application
swift build -c release

# Run unit tests (PixelMeCore – cross-platform, runs on Linux CI too)
swift test
```

## SPEC-Driven Development Reference

This project was designed following the six-step specification outlined in the PixelSnap 2 technical analysis:

1. **App infrastructure** – `AppDelegate`, menu bar, global `NSEvent` monitors, permissions onboarding
2. **Pixel capture engine** – `RealtimeCaptureEngine` (`CGDisplayCreateImage`), grayscale conversion
3. **Snapping & measurement** – Sobel edge map, `SnapEngine` projection, `castRay` distance
4. **UI overlay** – Transparent `NSPanel` at `.screenSaverWindow` level, adaptive labels
5. **Design tool integration** – AppleScript bridge (Sketch), Accessibility API (Figma/XD/Affinity)
6. **Export & clipboard** – CSS/SASS/JSON formatters, screenshot with configurable padding

## Coordinate system

macOS uses *logical points* which map to 2 × 2 physical pixels on Retina displays.
All public APIs accept and return logical coordinates unless explicitly stated otherwise:

```
P_relative = P_global − Screen_origin   // multi-monitor offset
U = P / Z                                // screen measurement → design units
G(x,y) = √(fx² + fy²)                  // Sobel gradient magnitude
```

## License

MIT
