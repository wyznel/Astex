// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Astex",
  platforms: [
    .macOS(.v26)
  ],
  dependencies: [
    .package(url: "https://github.com/mattt/ollama-swift.git", from: "1.8.0")
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .executableTarget(
      name: "Astex",
      dependencies: [
        .product(name: "Ollama", package: "ollama-swift")
      ],
      linkerSettings: [
        .linkedFramework("SwiftData")
      ]
    ),

    .testTarget(
      name: "AstexTests",
      dependencies: [
        "Astex"
      ]
    ),
  ],
  swiftLanguageModes: [.v6]
)
