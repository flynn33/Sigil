// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "RFSigilForsettiModules",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "RFSigilForsettiModules", targets: ["RFSigilForsettiModules"])
    ],
    dependencies: [
        .package(path: "../../Forsetti-Framwork")
    ],
    targets: [
        .target(
            name: "RFSigilForsettiModules",
            dependencies: [
                .product(name: "ForsettiCore", package: "Forsetti-Framwork")
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "RFSigilForsettiModulesTests",
            dependencies: [
                "RFSigilForsettiModules",
                .product(name: "ForsettiCore", package: "Forsetti-Framwork")
            ]
        )
    ]
)
