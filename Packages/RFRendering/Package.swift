// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "RFRendering",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "RFRendering", targets: ["RFRendering"])
    ],
    dependencies: [
        .package(path: "../RFCoreModels")
    ],
    targets: [
        .target(
            name: "RFRendering",
            dependencies: [
                .product(name: "RFCoreModels", package: "RFCoreModels")
            ]
        ),
        .testTarget(name: "RFRenderingTests", dependencies: ["RFRendering"])
    ]
)
