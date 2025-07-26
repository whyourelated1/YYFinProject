// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Utilities",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "PieChart",
            type: .static,
            targets: ["PieChart"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/airbnb/lottie-spm.git",
            from: "4.5.1"
        )
    ],
    targets: [
        .target(
            name: "PieChart",
            dependencies: [
                .product(name: "Lottie", package: "lottie-spm")
            ]
        ),
    ]
)

