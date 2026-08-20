// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FeatureDashboard",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "FeatureDashboard", targets: ["FeatureDashboard"])
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../DesignSystem")
    ],
    targets: [
        .target(
            name: "FeatureDashboard",
            dependencies: [
                .product(name: "CoreKit", package: "Core"),
                .product(name: "CoreNetwork", package: "Core"),
                .product(name: "CorePresentation", package: "Core"),
                .product(name: "DesignSystem", package: "DesignSystem")
            ]
        ),
        .testTarget(
            name: "FeatureDashboardTests",
            dependencies: [
                "FeatureDashboard",
                .product(name: "CoreTestSupport", package: "Core")
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)

