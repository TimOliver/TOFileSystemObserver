// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "TOFileSystemObserver",
    platforms: [
        .macOS(.v10_12),
        .iOS(.v8)
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "TOFileSystemObserver",
            type: .dynamic,
            targets: ["TOFileSystemObserver"]),
    ],
    dependencies: [ ],
    targets: [
        .target(
            name: "TOFileSystemObserver",
            dependencies: [],
            path: "TOFileSystemObserver",
            cSettings: [.define("TARGET_OS_OSX", .when(platforms: [.macOS]))]
        ),
    ]
)

