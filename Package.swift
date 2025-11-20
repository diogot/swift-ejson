// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-ejson",
    platforms: [
        .macOS(.v11),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "EJSONKit",
            targets: ["EJSONKit"]),
        .executable(
            name: "ejson",
            targets: ["ejson"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/jedisct1/swift-sodium.git", from: "0.9.1")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        .target(
            name: "EJSONKit",
            dependencies: [
                .product(name: "Clibsodium", package: "swift-sodium")
            ]),
        .executableTarget(
            name: "ejson",
            dependencies: ["EJSONKit"]),
        .testTarget(
            name: "EJSONKitTests",
            dependencies: ["EJSONKit"]),
    ]
)
