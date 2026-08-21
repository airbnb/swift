// swift-tools-version: 5.6
import PackageDescription

let package = Package(
  name: "AirbnbSwift",
  platforms: [.macOS(.v10_13)],
  products: [
    .plugin(name: "FormatSwift", targets: ["FormatSwift"])
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.3")
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
          .writeToPackageDirectory(reason: "Format Swift source files")
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
        .product(name: "ArgumentParser", package: "swift-argument-parser")
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
      url: "https://github.com/calda/SwiftFormat-nightly/releases/download/2026-08-21-b/SwiftFormat.artifactbundle.zip",
      checksum: "a14bac018f3816573ab68ab91923f8697f3266cda2e27c0c5dd6b40dc6f80dee"
    ),

    .binaryTarget(
      name: "SwiftLintBinary",
      url: "https://github.com/realm/SwiftLint/releases/download/0.62.2/SwiftLintBinary.artifactbundle.zip",
      checksum: "3047357eee0838a0bafc7a6e65cd1aad61734b30d7233e28f3434149fe02f522"
    ),
  ]
)
