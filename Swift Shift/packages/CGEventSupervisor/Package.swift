// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CGEventSupervisor",
    products: [
        .library(
            name: "CGEventSupervisor",
            targets: ["CGEventSupervisor"]),
    ],
    targets: [
        .target(
            name: "CGEventSupervisor",
            dependencies: []),
    ]
)
