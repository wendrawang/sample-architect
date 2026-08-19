// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FeatureTemplate",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "FeatureTemplate", targets: ["FeatureTemplate"])
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../DesignSystem")
    ],
    targets: [
        .target(
            name: "FeatureTemplate",
            dependencies: [
                .product(name: "CoreKit", package: "Core"),
                .product(name: "CoreNavigation", package: "Core"),
                .product(name: "CoreNetwork", package: "Core"),
                .product(name: "CorePresentation", package: "Core"),
                .product(name: "DesignSystem", package: "DesignSystem")
            ]
        ),
        .testTarget(
            name: "FeatureTemplateTests",
            dependencies: ["FeatureTemplate"]
        )
    ],
    swiftLanguageModes: [.v5]
)
