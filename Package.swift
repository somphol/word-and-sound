// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WordAndSound",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "WordAndSound", targets: ["WordAndSound"]),
    ],
    targets: [
        .target(
            name: "WordAndSoundCore",
            resources: [.copy("Resources")]
        ),
        .executableTarget(
            name: "WordAndSound",
            dependencies: ["WordAndSoundCore"]
        ),
        .testTarget(
            name: "WordAndSoundCoreTests",
            dependencies: ["WordAndSoundCore"]
        ),
    ]
)
