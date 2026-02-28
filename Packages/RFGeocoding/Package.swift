// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "RFGeocoding",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "RFGeocoding", targets: ["RFGeocoding"])
    ],
    dependencies: [
        .package(path: "../RFCoreModels")
    ],
    targets: [
        .target(
            name: "RFGeocoding",
            dependencies: [
                .product(name: "RFCoreModels", package: "RFCoreModels")
            ]
        ),
        .testTarget(name: "RFGeocodingTests", dependencies: ["RFGeocoding"])
    ]
)
