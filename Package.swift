// swift-tools-version: 5.6
import PackageDescription

let package = Package(
  name: "AirbnbSwift",
  platforms: [.macOS(.v10_13)],
  products: [
    .executable(name: "AirbnbSwiftFormatTool", targets: ["AirbnbSwiftFormatTool"]),
    .plugin(name: "FormatSwift", targets: ["FormatSwift"]),
  ],
  dependencies: [
    .package(url: "https://github.com/calda/SwiftFormat", exact: "0.49.11-beta-2"),
    // The `SwiftLintFramework` target uses "unsafe build flags" so Xcode doesn't
    // allow us to reference a specific version number. To work around that,
    // we can reference the specific commit for that version.
    //  - This is top-of-tree master from 7/22/22, because the most recent release version
    //    (0.47.1) seems to have issues in some real-world projects like airbnb/epoxy-ios.
    .package(url: "https://github.com/realm/SwiftLint", revision: "c5aa806"),
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.3"),
  ],
  targets: [
    .plugin(
      name: "FormatSwift",
      capability: .command(
        intent: .custom(
          verb: "format",
          description: "Formats Swift source files according to the Airbnb Swift Style Guide"),
        permissions: [
          .writeToPackageDirectory(reason: "Format Swift source files"),
        ]),
      dependencies: [
        "AirbnbSwiftFormatTool",
        .product(name: "swiftformat", package: "SwiftFormat"),
        .product(name: "swiftlint", package: "SwiftLint"),
      ]),
    .executableTarget(
      name: "AirbnbSwiftFormatTool",
      dependencies: [
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      resources: [
        .process("airbnb.swiftformat"),
        .process("swiftlint.yml"),
      ]),
  ])
