// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "Navigator",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .tvOS(.v18),
        .watchOS(.v11)
    ],
    products: [
        .library(
            name: "Navigator",
            targets: ["Navigator"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "602.0.0")
    ],
    targets: [
        // Macro implementation
        .macro(
            name: "NavigatorMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),

        // Main library
        .target(
            name: "Navigator",
            dependencies: ["NavigatorMacros"],
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny"),
                .enableExperimentalFeature("StrictConcurrency"),
                .defaultIsolation(MainActor.self)
            ]
        ),

        // Tests
        .testTarget(
            name: "NavigatorTests",
            dependencies: ["Navigator"]
        ),
        .testTarget(
            name: "NavigatorMacrosTests",
            dependencies: [
                "NavigatorMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax")
            ]
        )
    ]
)
