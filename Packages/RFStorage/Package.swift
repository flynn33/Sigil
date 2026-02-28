// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "RFStorage",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "RFStorage", targets: ["RFStorage"])
    ],
    dependencies: [
        .package(path: "../RFCoreModels"),
        .package(path: "../RFSecurity")
    ],
    targets: [
        .target(
            name: "RFStorage",
            dependencies: [
                .product(name: "RFCoreModels", package: "RFCoreModels"),
                .product(name: "RFSecurity", package: "RFSecurity")
            ]
        ),
        .testTarget(name: "RFStorageTests", dependencies: ["RFStorage"])
    ]
)
