// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "chatoly",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "chatoly",
            targets: ["chatoly"]
        ),
        .executable(
            name: "chatoly-stream",
            targets: ["chatoly-stream"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "chatoly",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .executableTarget(
            name: "chatoly-stream",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
    ]
)