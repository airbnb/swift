// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TiseFormatter",
    platforms: [.macOS(.v12)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .plugin(name: "TiseFormatterPlugin", targets: ["TiseFormatterPlugin"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .plugin(
            name: "TiseFormatterPlugin",
            capability: .buildTool(),
            dependencies: [
                .target(name: "SwiftLintBinary", condition: .when(platforms: [.macOS])),
                .target(name: "SwiftFormatBinary", condition: .when(platforms: [.macOS])),
            ]
        ),
        .binaryTarget(
            name: "SwiftLintBinary",
            url: "https://github.com/realm/SwiftLint/releases/download/0.51.0/SwiftLintBinary-macos.artifactbundle.zip",
            checksum: "9fbfdf1c2a248469cfbe17a158c5fbf96ac1b606fbcfef4b800993e7accf43ae"
        ),
        .binaryTarget(
            name: "SwiftFormatBinary",
            url: "https://github.com/nicklockwood/SwiftFormat/releases/download/0.51.7/swiftformat.artifactbundle.zip",
            checksum: "644d46307c87e516b38681b7ea986e09397ff11951ee4b76607bb8369bcbe438"
        )
    ]
)
