// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MacStreamer",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "MacStreamer",
            path: "Sources/MacStreamer"
        )
    ]
)
