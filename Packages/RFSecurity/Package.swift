// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "RFSecurity",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "RFSecurity", targets: ["RFSecurity"])
    ],
    dependencies: [
        .package(path: "../RFCoreModels")
    ],
    targets: [
        .target(
            name: "RFSecurity",
            dependencies: [
                .product(name: "RFCoreModels", package: "RFCoreModels")
            ]
        ),
        .testTarget(name: "RFSecurityTests", dependencies: ["RFSecurity"])
    ]
)
