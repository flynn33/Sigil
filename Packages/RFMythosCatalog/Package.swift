// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "RFMythosCatalog",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "RFMythosCatalog", targets: ["RFMythosCatalog"])
    ],
    dependencies: [
        .package(path: "../RFCoreModels")
    ],
    targets: [
        .target(
            name: "RFMythosCatalog",
            dependencies: [
                .product(name: "RFCoreModels", package: "RFCoreModels")
            ]
        ),
        .testTarget(name: "RFMythosCatalogTests", dependencies: ["RFMythosCatalog"])
    ]
)
