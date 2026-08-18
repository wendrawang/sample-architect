// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Core",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "CoreKit", targets: ["CoreKit"]),
        .library(name: "CoreNavigation", targets: ["CoreNavigation"]),
        .library(name: "CoreNetwork", targets: ["CoreNetwork"]),
        .library(name: "CorePresentation", targets: ["CorePresentation"]),
        .library(name: "CoreGuards", targets: ["CoreGuards"])
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
        .testTarget(
            name: "CorePresentationTests",
            dependencies: ["CorePresentation"]
        )
    ],
    swiftLanguageModes: [.v5]
)

