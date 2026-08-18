// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FeatureMore",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "FeatureMore", targets: ["FeatureMore"])
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../DesignSystem")
    ],
    targets: [
        .target(
            name: "FeatureMore",
            dependencies: [
                .product(name: "CoreKit", package: "Core"),
                .product(name: "CorePresentation", package: "Core"),
                .product(name: "DesignSystem", package: "DesignSystem")
            ]
        )
    ],
    swiftLanguageModes: [.v5]
)

