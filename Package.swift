// swift-tools-version:5.6
import Foundation
import PackageDescription

let package = Package(
    name: "SnapshotTesting",
    platforms: [
        .iOS(.v14),
        .macOS(.v10_11),
        .tvOS(.v10)
    ],
    products: [
        .library(
            name: "SnapshotTesting",
            targets: ["SnapshotTesting"]),
    ],
    dependencies: [
//        .package(url: "https://github.com/SnapKit/SnapKit.git", from: "5.6.0")
    ],
    targets: [
        .target(
            name: "SnapshotTesting",
            dependencies: [
//                .byName(name: "SnapKit")
            ]
        ),
        .testTarget(
            name: "SnapshotTestingTests",
            dependencies: ["SnapshotTesting"]),
    ]
)
