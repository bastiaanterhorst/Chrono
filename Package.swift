// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Chrono",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
        .watchOS(.v8),
        .tvOS(.v15)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Chrono",
            targets: ["Chrono"]),
        .executable(
            name: "Benchmark",
            targets: ["Benchmark"]),
        .executable(
            name: "Examples",
            targets: ["Examples"])
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Chrono",
            swiftSettings: [
                .define("CHRONO_VERSION_STRING=\"0.1.0\"")
            ]),
        .executableTarget(
            name: "Benchmark",
            dependencies: ["Chrono"]),
        .executableTarget(
            name: "Examples",
            dependencies: ["Chrono"]),
        .testTarget(
            name: "ChronoTests",
            dependencies: ["Chrono"]
        ),
    ]
)
