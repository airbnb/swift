// swift-tools-version: 5.6
import PackageDescription

let package = Package(
    name: "RakuyoSwift",
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
                    description: "Formats Swift source files according to the Rakuyo Swift Style Guide"
                ),
                permissions: [
                    .writeToPackageDirectory(reason: "Format Swift source files"),
                ]
            ),
            dependencies: [
                "RakuyoSwiftFormatTool",
                "SwiftFormat",
                "SwiftLintBinary",
            ]
        ),

        .executableTarget(
            name: "RakuyoSwiftFormatTool",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            resources: [
                .process("rakuyo.swiftformat"),
                .process("swiftlint.yml"),
            ]
        ),

        .testTarget(
            name: "RakuyoSwiftFormatToolTests",
            dependencies: ["RakuyoSwiftFormatTool"]
        ),

        .binaryTarget(
            name: "SwiftFormat",
            url: "https://github.com/nicklockwood/SwiftFormat/releases/download/0.53.7/SwiftFormat.artifactbundle.zip",
            checksum: "7f772d46392f7dd98450dd59bf3d01d5a951b65ff2e294af34b012be351358f3"
        ),

        .binaryTarget(
            name: "SwiftLintBinary",
            url: "https://github.com/realm/SwiftLint/releases/download/0.54.0/SwiftLintBinary-macos.artifactbundle.zip",
            checksum: "963121d6babf2bf5fd66a21ac9297e86d855cbc9d28322790646b88dceca00f1"
        ),
    ]
)
