// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DesignSystem",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "DesignSystem", targets: ["DesignSystem"])
    ],
    dependencies: [
        .package(path: "../Core")
    ],
    targets: [
        .target(
            name: "DesignSystem",
            dependencies: [
                .product(name: "CorePresentation", package: "Core")
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)

