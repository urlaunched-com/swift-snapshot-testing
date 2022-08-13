// swift-tools-version:5.5
import Foundation
import PackageDescription

let package = Package(
    name: "SnapshotTesting",
    platforms: [
        .iOS(.v14),
        .macOS(.v10_10),
        .tvOS(.v10)
    ],
    products: [
        .library(
            name: "SnapshotTesting",
            targets: ["SnapshotTesting"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SnapshotTesting",
            dependencies: []
        ),
        .testTarget(
            name: "SnapshotTestingTests",
            dependencies: ["SnapshotTesting"]),
    ]
)
