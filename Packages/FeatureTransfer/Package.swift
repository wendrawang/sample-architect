// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FeatureTransfer",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "FeatureTransfer", targets: ["FeatureTransfer"])
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../DesignSystem")
    ],
    targets: [
        .target(
            name: "FeatureTransfer",
            dependencies: [
                .product(name: "CoreKit", package: "Core"),
                .product(name: "CoreNavigation", package: "Core"),
                .product(name: "CoreNetwork", package: "Core"),
                .product(name: "CorePresentation", package: "Core"),
                .product(name: "DesignSystem", package: "DesignSystem")
            ]
        )
    ],
    swiftLanguageModes: [.v5]
)

