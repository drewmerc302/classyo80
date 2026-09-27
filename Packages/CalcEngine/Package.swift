// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CalcEngine",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "CalcEngine", targets: ["CalcEngine"])
    ],
    targets: [
        .target(name: "CalcEngine"),
        .testTarget(name: "CalcEngineTests", dependencies: ["CalcEngine"]),
    ]
)
