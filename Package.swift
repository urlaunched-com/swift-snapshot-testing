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
    dependencies: [
//        .package(url: "https://github.com/uber/ios-snapshot-test-case.git", from: "8.0.0")
    ],
    targets: [
        .target(
            name: "SnapshotTesting",
            dependencies: [
//                .product(name: "iOSSnapshotTestCase", package: "ios-snapshot-test-case")
            ]
        ),
        .testTarget(
            name: "SnapshotTestingTests",
            dependencies: ["SnapshotTesting"]),
    ]
)
