// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "AppleSharedUI",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
    ],
    products: [
        .library(name: "AppleSharedUI", targets: ["AppleSharedUI"]),
    ],
    targets: [
        .target(name: "AppleSharedUI", path: "Sources/AppleSharedUI"),
    ]
)
