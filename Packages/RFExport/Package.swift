// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "RFExport",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "RFExport", targets: ["RFExport"])
    ],
    dependencies: [
        .package(path: "../RFCoreModels"),
        .package(path: "../RFRendering")
    ],
    targets: [
        .target(
            name: "RFExport",
            dependencies: [
                .product(name: "RFCoreModels", package: "RFCoreModels"),
                .product(name: "RFRendering", package: "RFRendering")
            ]
        ),
        .testTarget(name: "RFExportTests", dependencies: ["RFExport"])
    ]
)
