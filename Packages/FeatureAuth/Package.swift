// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FeatureAuth",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "FeatureAuth", targets: ["FeatureAuth"])
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../DesignSystem")
    ],
    targets: [
        .target(
            name: "FeatureAuth",
            dependencies: [
                .product(name: "CoreKit", package: "Core"),
                .product(name: "CoreNavigation", package: "Core"),
                .product(name: "CoreNetwork", package: "Core"),
                .product(name: "CorePresentation", package: "Core"),
                .product(name: "DesignSystem", package: "DesignSystem")
            ],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "FeatureAuthTests",
            dependencies: ["FeatureAuth"]
        )
    ],
    swiftLanguageModes: [.v6]
)

