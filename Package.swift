// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AppXray",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "AppXrayKit", targets: ["AppXrayKit"]),
        .executable(name: "appxray", targets: ["appxray"])
    ],
    targets: [
        .target(
            name: "AppXrayKit",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .executableTarget(
            name: "appxray",
            dependencies: ["AppXrayKit"],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "AppXrayKitTests",
            dependencies: ["AppXrayKit"]
        )
    ]
)
