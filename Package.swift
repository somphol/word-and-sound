// swift-tools-version: 5.9
import PackageDescription

var products: [Product] = [
    .executable(name: "wordandsound-selftest", targets: ["SelfTestCLI"]),
]

var targets: [Target] = [
    .target(
        name: "WordAndSoundCore",
        resources: [.copy("Resources")]
    ),
    .executableTarget(
        name: "SelfTestCLI",
        dependencies: ["WordAndSoundCore"]
    ),
    .testTarget(
        name: "WordAndSoundCoreTests",
        dependencies: ["WordAndSoundCore"]
    ),
]

#if os(macOS)
products.append(.executable(name: "WordAndSound", targets: ["WordAndSound"]))
targets.append(
    .executableTarget(
        name: "WordAndSound",
        dependencies: ["WordAndSoundCore"]
    )
)
#endif

let package = Package(
    name: "WordAndSound",
    platforms: [.macOS(.v14)],
    products: products,
    targets: targets
)
