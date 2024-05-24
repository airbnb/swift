// swift-tools-version: 5.8
import PackageDescription

let package = Package(
    name: "RakuyoSwift",
    platforms: [.macOS(.v13)],
    products: [
        .plugin(name: "FormatSwift", targets: ["FormatSwift"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.4.0"),
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
            url: "https://github.com/nicklockwood/SwiftFormat/releases/download/0.53.8/SwiftFormat.artifactbundle.zip",
            checksum: "12c4cd6e1382479cd38bba63c81eb50121f9b2212a8b1f8f5fa9ed1d1c6d07d1"
        ),

        .binaryTarget(
            name: "SwiftLintBinary",
            url: "https://github.com/realm/SwiftLint/releases/download/0.54.0/SwiftLintBinary-macos.artifactbundle.zip",
            checksum: "963121d6babf2bf5fd66a21ac9297e86d855cbc9d28322790646b88dceca00f1"
        ),
    ]
)
