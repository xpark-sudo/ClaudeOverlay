// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ClaudeOverlay",
    defaultLocalization: "en",
    platforms: [.macOS(.v12)],
    targets: [
        .executableTarget(
            name: "ClaudeOverlay",
            path: "Sources",
            resources: [
                .process("Resources")
            ],
            linkerSettings: [
                .linkedFramework("Carbon"),
                .linkedFramework("AppKit")
            ]
        )
    ]
)
