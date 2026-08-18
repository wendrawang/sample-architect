// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FeatureQRIS",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "FeatureQRIS", targets: ["FeatureQRIS"])
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../DesignSystem")
    ],
    targets: [
        .target(
            name: "FeatureQRIS",
            dependencies: [
                .product(name: "CoreKit", package: "Core"),
                .product(name: "CorePresentation", package: "Core"),
                .product(name: "DesignSystem", package: "DesignSystem")
            ]
        )
    ],
    swiftLanguageModes: [.v5]
)

