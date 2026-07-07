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
      url: "https://github.com/calda/SwiftFormat-nightly/releases/download/2026-07-07/SwiftFormat.artifactbundle.zip",
      checksum: "aa108373407da339355f896c77254519e667e5905db9d239b767ac315e275b4c"
    ),

    .binaryTarget(
      name: "SwiftLintBinary",
      url: "https://github.com/realm/SwiftLint/releases/download/0.62.2/SwiftLintBinary.artifactbundle.zip",
      checksum: "3047357eee0838a0bafc7a6e65cd1aad61734b30d7233e28f3434149fe02f522"
    ),
  ]
)
