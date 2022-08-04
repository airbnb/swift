// swift-tools-version: 5.6
import PackageDescription

let package = Package(
  name: "AirbnbSwift",
  platforms: [.macOS(.v10_13)],
  products: [
    .plugin(name: "FormatSwift", targets: ["FormatSwift"]),
  ],
  dependencies: [
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
        "SwiftFormat",
        "SwiftLintBinary",
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

    // As of Xcode 13.4 / 14.0, there's an issue that causes projects with this repo
    // as a dependency to spin indefinitely at 100% CPU resolving this package's binary
    // dependencies if we use remote binary targets. As a workaround, we can instead
    // include the artifact bundles directly in this repo instead.
    .binaryTarget(
      name: "SwiftFormat",
      path: "resources/SwiftFormat.artifactbundle.zip"),

    .binaryTarget(
      name: "SwiftLintBinary",
      path: "resources/SwiftLintBinary.artifactbundle.zip"),
  ])
