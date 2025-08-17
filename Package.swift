// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AIChatBot",
    platforms: [
        .iOS(.v14),
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "AIChatBot",
            targets: ["AIChatBot"]),
    ],
    dependencies: [
        // Add any external dependencies here if needed
    ],
    targets: [
        .target(
            name: "AIChatBot",
            dependencies: [],
            path: "AIChatBot"),
        .testTarget(
            name: "AIChatBotTests",
            dependencies: ["AIChatBot"],
            path: "AIChatBotTests"),
    ]
) 