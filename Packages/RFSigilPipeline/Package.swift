// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "RFSigilPipeline",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "RFSigilPipeline", targets: ["RFSigilPipeline"])
    ],
    dependencies: [
        .package(path: "../RFCoreModels"),
        .package(path: "../RFEngineData")
    ],
    targets: [
        .target(
            name: "RFSigilPipeline",
            dependencies: [
                .product(name: "RFCoreModels", package: "RFCoreModels"),
                .product(name: "RFEngineData", package: "RFEngineData")
            ]
        ),
        .testTarget(name: "RFSigilPipelineTests", dependencies: ["RFSigilPipeline"])
    ]
)
