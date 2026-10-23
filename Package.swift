// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "display-disconnect",
  platforms: [.macOS(.v14)],
  products: [
    .executable(name: "dispctl", targets: ["dispctl"]),
    .executable(name: "DisplayDisconnectApp", targets: ["DisplayDisconnectApp"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0")
  ],
  targets: [
    .target(name: "DisplayCore"),
    .target(name: "DisplayBackendCG", dependencies: ["DisplayCore"]),
    .target(name: "DisplayStorage", dependencies: ["DisplayCore"]),
    .executableTarget(
      name: "dispctl",
      dependencies: [
        "DisplayCore",
        "DisplayBackendCG",
        "DisplayStorage",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ]
    ),
    .executableTarget(
      name: "DisplayDisconnectApp",
      dependencies: ["DisplayCore", "DisplayBackendCG", "DisplayStorage"]
    ),
    .testTarget(name: "DisplayCoreTests", dependencies: ["DisplayCore"]),
    .testTarget(name: "DisplayStorageTests", dependencies: ["DisplayStorage", "DisplayCore"]),
    .testTarget(name: "DisplayBackendCGTests", dependencies: ["DisplayBackendCG", "DisplayCore"]),
  ]
)
