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
    ],
    targets: [
        .executableTarget(
            name: "chatoly",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
    ]
)