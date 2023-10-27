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

    .testTarget(
      name: "AirbnbSwiftFormatToolTests",
      dependencies: ["AirbnbSwiftFormatTool"]),

    .binaryTarget(
      name: "SwiftFormat",
      url: "https://github.com/calda/SwiftFormat/releases/download/0.53-beta-3/SwiftFormat.artifactbundle.zip",
      checksum: "ef7283d3dab42809d3faa812dbad71d4f35cd2863db60bc920128fcc12a36a1e"),

    .binaryTarget(
      name: "SwiftLintBinary",
      url: "https://github.com/realm/SwiftLint/releases/download/0.53.0/SwiftLintBinary-macos.artifactbundle.zip",
      checksum: "03416a4f75f023e10f9a76945806ddfe70ca06129b895455cc773c5c7d86b73e"),
  ])

// Emit an error on Linux, so Swift Package Manager's platform support detection doesn't say this package supports Linux
// https://github.com/airbnb/swift/discussions/197#discussioncomment-4055303
#if os(Linux)
#error("Linux is currently not supported")
#endif
