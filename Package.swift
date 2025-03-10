// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Chrono.swift",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
        .watchOS(.v8),
        .tvOS(.v15)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Chrono.swift",
            type: .dynamic,
            targets: ["Chrono.swift"]),
        .executable(
            name: "ChronoSwiftApp",
            targets: ["ChronoSwiftApp"]),
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
            name: "Chrono.swift",
            swiftSettings: [
                .define("CHRONO_VERSION_STRING=\"0.1.0\"")
            ]),
        .executableTarget(
            name: "ChronoSwiftApp",
            dependencies: ["Chrono.swift"],
            path: "Sources",
            sources: ["App.swift"]),
        .executableTarget(
            name: "Benchmark",
            dependencies: ["Chrono.swift"]),
        .executableTarget(
            name: "Examples",
            dependencies: ["Chrono.swift"]),
        .testTarget(
            name: "Chrono.swiftTests",
            dependencies: ["Chrono.swift"]
        ),
    ]
)
