// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MetaRouterFramework",
    platforms: [
         .iOS(.v13), // Specify minimum iOS 13.0
     ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "MetaRouterFramework",
            targets: ["MetaRouterFramework"]),
    ],
    dependencies: [.package(url: "git@github.com:segmentio/analytics-swift.git", .upToNextMajor(from: "1.7.3")),],
    targets: [
          .target(
              name: "MetaRouterFramework",
              dependencies: [
                         .product(name: "Segment", package: "analytics-swift")
                     ])
      ]
)
