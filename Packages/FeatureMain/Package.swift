// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FeatureMain",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "FeatureMain", targets: ["FeatureMain"])
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../DesignSystem"),
        .package(path: "../FeatureDashboard"),
        .package(path: "../FeatureFinancial"),
        .package(path: "../FeatureQRIS"),
        .package(path: "../FeatureRewards"),
        .package(path: "../FeatureMore"),
        .package(path: "../FeatureTransfer")
    ],
    targets: [
        .target(
            name: "FeatureMain",
            dependencies: [
                .product(name: "CoreKit", package: "Core"),
                .product(name: "CoreNavigation", package: "Core"),
                .product(name: "CoreNetwork", package: "Core"),
                .product(name: "CorePresentation", package: "Core"),
                .product(name: "DesignSystem", package: "DesignSystem"),
                .product(name: "FeatureDashboard", package: "FeatureDashboard"),
                .product(name: "FeatureFinancial", package: "FeatureFinancial"),
                .product(name: "FeatureQRIS", package: "FeatureQRIS"),
                .product(name: "FeatureRewards", package: "FeatureRewards"),
                .product(name: "FeatureMore", package: "FeatureMore"),
                .product(name: "FeatureTransfer", package: "FeatureTransfer")
            ]
        )
    ],
    swiftLanguageModes: [.v5]
)
