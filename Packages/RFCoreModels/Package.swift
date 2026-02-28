// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "RFCoreModels",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "RFCoreModels", targets: ["RFCoreModels"])
    ],
    targets: [
        .target(name: "RFCoreModels"),
        .testTarget(name: "RFCoreModelsTests", dependencies: ["RFCoreModels"])
    ]
)
