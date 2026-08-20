// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Core",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "CoreKit", targets: ["CoreKit"]),
        .library(name: "CoreNavigation", targets: ["CoreNavigation"]),
        .library(name: "CoreNetwork", targets: ["CoreNetwork"]),
        .library(name: "CorePresentation", targets: ["CorePresentation"]),
        .library(name: "CoreGuards", targets: ["CoreGuards"]),
        // Hanya untuk test target. Tidak pernah di-link ke aplikasi.
        .library(name: "CoreTestSupport", targets: ["CoreTestSupport"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/Alamofire/Alamofire.git",
            exact: "5.12.0"
        )
    ],
    targets: [
        .target(name: "CoreKit"),
        .target(
            name: "CoreNavigation",
            dependencies: ["CoreKit"]
        ),
        .target(
            name: "CoreNetwork",
            dependencies: [
                "CoreKit",
                .product(name: "Alamofire", package: "Alamofire")
            ]
        ),
        .target(name: "CorePresentation", dependencies: ["CoreKit"]),
        .target(name: "CoreGuards", dependencies: ["CoreKit"]),
        .target(name: "CoreTestSupport"),
        .testTarget(
            name: "CoreNavigationTests",
            dependencies: ["CoreNavigation"]
        ),
        .testTarget(
            name: "CorePresentationTests",
            dependencies: ["CorePresentation"]
        ),
        .testTarget(
            name: "CoreNetworkTests",
            dependencies: [
                "CoreNetwork",
                .product(name: "Alamofire", package: "Alamofire")
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)
