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
          description: "Formats Swift source files according to the Airbnb Swift Style Guide"
        ),
        permissions: [
          .writeToPackageDirectory(reason: "Format Swift source files"),
        ]
      ),
      dependencies: [
        "AirbnbSwiftFormatTool",
        "swiftformat",
        "SwiftLintBinary",
      ]
    ),

    .executableTarget(
      name: "AirbnbSwiftFormatTool",
      dependencies: [
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      resources: [
        .process("airbnb.swiftformat"),
        .process("swiftlint.yml"),
      ]
    ),

    .testTarget(
      name: "AirbnbSwiftFormatToolTests",
      dependencies: ["AirbnbSwiftFormatTool"]
    ),

    .binaryTarget(
      name: "swiftformat",
      url: "https://github.com/calda/SwiftFormat-nightly/releases/download/2025-07-09/SwiftFormat.artifactbundle.zip",
      checksum: "0feced7d468d909095b4d69e4a17c3a8cb4cd219b3b5574c7835275d3305737e"
    ),

    .binaryTarget(
      name: "SwiftLintBinary",
      url: "https://github.com/realm/SwiftLint/releases/download/0.55.1/SwiftLintBinary-macos.artifactbundle.zip",
      checksum: "722a705de1cf4e0e07f2b7d2f9f631f3a8b2635a0c84cce99f9677b38aa4a1d6"
    ),
  ]
)
