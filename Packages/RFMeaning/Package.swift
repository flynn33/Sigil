// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "RFMeaning",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "RFMeaning", targets: ["RFMeaning"])
    ],
    dependencies: [
        .package(path: "../RFCoreModels"),
        .package(path: "../RFEngineData")
    ],
    targets: [
        .target(
            name: "RFMeaning",
            dependencies: [
                .product(name: "RFCoreModels", package: "RFCoreModels"),
                .product(name: "RFEngineData", package: "RFEngineData")
            ]
        ),
        .testTarget(name: "RFMeaningTests", dependencies: ["RFMeaning"])
    ]
)
