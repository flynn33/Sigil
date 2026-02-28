// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "RFEngineData",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "RFEngineData", targets: ["RFEngineData"])
    ],
    dependencies: [
        .package(path: "../RFCoreModels")
    ],
    targets: [
        .target(
            name: "RFEngineData",
            dependencies: [
                .product(name: "RFCoreModels", package: "RFCoreModels")
            ],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "RFEngineDataTests",
            dependencies: ["RFEngineData"]
        )
    ]
)
