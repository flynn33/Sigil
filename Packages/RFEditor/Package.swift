// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "RFEditor",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "RFEditor", targets: ["RFEditor"])
    ],
    dependencies: [
        .package(path: "../RFCoreModels"),
        .package(path: "../RFMythosCatalog")
    ],
    targets: [
        .target(
            name: "RFEditor",
            dependencies: [
                .product(name: "RFCoreModels", package: "RFCoreModels"),
                .product(name: "RFMythosCatalog", package: "RFMythosCatalog")
            ]
        ),
        .testTarget(name: "RFEditorTests", dependencies: ["RFEditor"])
    ]
)
