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
    dependencies: [
        // Build-time only: generates DocC for GitHub Pages. App X-Ray itself has
        // no third-party *runtime* dependencies.
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.0.0")
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
