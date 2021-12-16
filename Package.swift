// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftConnect",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "SwiftConnect",
            targets: ["SwiftConnect"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire", .upToNextMajor(from: "5.5.0"))
    ],
    targets: [
        .target(
            name: "SwiftConnect",
            dependencies: [
                .product(name: "Alamofire", package: "Alamofire")
            ]
        )
    ]
)
