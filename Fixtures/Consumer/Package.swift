// swift-tools-version: 6.0
import PackageDescription

// Each host selects its own language mode; the local dependency keeps Swift 6.
let package = Package(
    name: "JXSegmentedViewConsumerCompatibility",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "ConsumerSwift5", targets: ["ConsumerSwift5"]),
        .library(name: "ConsumerSwift6", targets: ["ConsumerSwift6"]),
    ],
    dependencies: [.package(name: "JXSegmentedView", path: "../..")],
    targets: [
        .target(
            name: "ConsumerSwift5",
            dependencies: [.product(name: "JXSegmentedView", package: "JXSegmentedView")],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .target(
            name: "ConsumerSwift6",
            dependencies: [.product(name: "JXSegmentedView", package: "JXSegmentedView")],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ],
    swiftLanguageModes: [.v5, .v6]
)
