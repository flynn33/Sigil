// swift-tools-version: 5.10
import PackageDescription

let forsettiDependency: Target.Dependency = .product(
    name: "ForsettiCore",
    package: "Forsetti-Framework-Mac-iOS"
)

let package = Package(
    name: "Sigil",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "RFSigilCoreModels", targets: ["RFSigilCoreModels"]),
        .library(name: "RFSigilSourceAuthority", targets: ["RFSigilSourceAuthority"]),
        .library(name: "RFSigilAPSIntegration", targets: ["RFSigilAPSIntegration"]),
        .library(name: "RFSigilAeostaraIntegration", targets: ["RFSigilAeostaraIntegration"]),
        .library(name: "RFSigilVisibleGlyph", targets: ["RFSigilVisibleGlyph"]),
        .library(name: "RFSigilPipelinePlaceholder", targets: ["RFSigilPipelinePlaceholder"]),
        .library(name: "RFSigilPrivacySecurity", targets: ["RFSigilPrivacySecurity"]),
        .library(name: "RFSigilDiagnostics", targets: ["RFSigilDiagnostics"]),
        .library(name: "RFSigilUIModule", targets: ["RFSigilUIModule"]),
        .library(name: "RFSigilForsettiModules", targets: ["RFSigilForsettiModules"]),
        .library(name: "RFSigilRuntime", targets: ["RFSigilRuntime"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/flynn33/Forsetti-Framework-Mac-iOS.git",
            revision: "43eef7a739f3b78253c64aa4b070521ab5b1f43c"
        )
    ],
    targets: [
        .target(name: "RFSigilCoreModels"),
        .target(
            name: "RFSigilSourceAuthority",
            dependencies: ["RFSigilCoreModels", forsettiDependency]
        ),
        .target(
            name: "RFSigilAPSIntegration",
            dependencies: ["RFSigilCoreModels", forsettiDependency]
        ),
        .target(
            name: "RFSigilAeostaraIntegration",
            dependencies: ["RFSigilCoreModels", "RFSigilVisibleGlyph", forsettiDependency]
        ),
        .target(
            name: "RFSigilVisibleGlyph",
            dependencies: ["RFSigilCoreModels", "RFSigilDiagnostics", forsettiDependency]
        ),
        .target(
            name: "RFSigilPipelinePlaceholder",
            dependencies: ["RFSigilCoreModels", forsettiDependency]
        ),
        .target(
            name: "RFSigilPrivacySecurity",
            dependencies: ["RFSigilCoreModels", forsettiDependency]
        ),
        .target(
            name: "RFSigilDiagnostics",
            dependencies: ["RFSigilCoreModels", forsettiDependency]
        ),
        .target(
            name: "RFSigilUIModule",
            dependencies: ["RFSigilCoreModels", forsettiDependency]
        ),
        .target(
            name: "RFSigilForsettiModules",
            dependencies: [
                "RFSigilCoreModels",
                "RFSigilSourceAuthority",
                "RFSigilAPSIntegration",
                "RFSigilAeostaraIntegration",
                "RFSigilVisibleGlyph",
                "RFSigilPipelinePlaceholder",
                "RFSigilPrivacySecurity",
                "RFSigilDiagnostics",
                "RFSigilUIModule",
                forsettiDependency
            ]
        ),
        .target(
            name: "RFSigilRuntime",
            dependencies: [
                "RFSigilCoreModels",
                "RFSigilSourceAuthority",
                "RFSigilAPSIntegration",
                "RFSigilAeostaraIntegration",
                "RFSigilVisibleGlyph",
                "RFSigilPipelinePlaceholder",
                "RFSigilPrivacySecurity",
                "RFSigilDiagnostics",
                "RFSigilForsettiModules",
                forsettiDependency
            ]
        ),
        .testTarget(
            name: "SigilTests",
            dependencies: [
                "RFSigilCoreModels",
                "RFSigilSourceAuthority",
                "RFSigilAPSIntegration",
                "RFSigilAeostaraIntegration",
                "RFSigilVisibleGlyph",
                "RFSigilPipelinePlaceholder",
                "RFSigilPrivacySecurity",
                "RFSigilDiagnostics",
                "RFSigilForsettiModules",
                "RFSigilRuntime",
                forsettiDependency
            ]
        )
    ]
)
