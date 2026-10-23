// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "display-disconnect",
  platforms: [.macOS(.v14)],
  products: [
    .executable(name: "dispctl", targets: ["dispctl"])
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0")
  ],
  targets: [
    .target(name: "DisplayCore"),
    .target(name: "DisplayBackendCG", dependencies: ["DisplayCore"]),
    .executableTarget(
      name: "dispctl",
      dependencies: [
        "DisplayCore",
        "DisplayBackendCG",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ]
    ),
    .testTarget(name: "DisplayCoreTests", dependencies: ["DisplayCore"]),
  ]
)
