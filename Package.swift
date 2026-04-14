// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "PixelMe",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "PixelMe", targets: ["PixelMe"]),
        .library(name: "PixelMeCore", targets: ["PixelMeCore"])
    ],
    targets: [
        .executableTarget(
            name: "PixelMe",
            dependencies: ["PixelMeCore"],
            path: "Sources/PixelMe"
        ),
        .target(
            name: "PixelMeCore",
            path: "Sources/PixelMeCore"
        ),
        .testTarget(
            name: "PixelMeTests",
            dependencies: ["PixelMeCore"],
            path: "Tests/PixelMeTests"
        )
    ]
)
