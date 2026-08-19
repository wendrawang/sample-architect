// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FeatureSplash",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "FeatureSplash", targets: ["FeatureSplash"])
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../DesignSystem")
    ],
    targets: [
        .target(
            name: "FeatureSplash",
            dependencies: [
                .product(name: "CoreKit", package: "Core"),
                .product(name: "CoreNetwork", package: "Core"),
                .product(name: "CorePresentation", package: "Core"),
                .product(name: "DesignSystem", package: "DesignSystem")
            ]
        ),
        .testTarget(
            name: "FeatureSplashTests",
            dependencies: ["FeatureSplash"]
        )
    ],
    swiftLanguageModes: [.v5]
)
