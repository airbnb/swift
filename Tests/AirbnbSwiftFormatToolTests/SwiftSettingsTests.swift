// Created by Cal Stephens on 9/18/23.
// Copyright © 2023 Airbnb Inc. All rights reserved.

import XCTest
@testable import AirbnbSwiftFormatTool

extension SwiftSettings {
  static let testCaseSwiftSettings = """
    extension [SwiftSetting] {
      static func airbnbDefault() -> [SwiftSetting] {
        [
          .enableUpcomingFeature("TestCase")
        ]
      }
    }
    """
}


final class SwiftSettingsTests: XCTestCase {

  @available(macOS 13.0, *)
  func testUpdatesSwiftSettings() {
    let input = """
    // swift-tools-version: 5.8
    import PackageDescription

    let package = Package(
      name: "MyPackage",
      targets: [.target(name: "MyTarget", swiftSettings: .airbnbDefault())])

    extension [SwiftSetting] {
      static func airbnbDefault() -> [SwiftSetting] {
        []
      }
    }
    """

    let expectedOutput = """
    // swift-tools-version: 5.8
    import PackageDescription

    let package = Package(
      name: "MyPackage",
      targets: [.target(name: "MyTarget", swiftSettings: .airbnbDefault())])

    extension [SwiftSetting] {
      static func airbnbDefault() -> [SwiftSetting] {
        [
          .enableUpcomingFeature("TestCase")
        ]
      }
    }
    """

    let updatedManifest = SwiftSettings.updateContentsOfPackageManifest(input, with: SwiftSettings.testCaseSwiftSettings)
    XCTAssertEqual(updatedManifest, expectedOutput)
  }

  @available(macOS 13.0, *)
  func testPreservesExistingSettings() {
    let input = """
    // swift-tools-version: 5.8
    import PackageDescription

    let package = Package(
      name: "MyPackage",
      targets: [.target(name: "MyTarget", swiftSettings: .airbnbDefault())])

    extension [SwiftSetting] {
      static func airbnbDefault() -> [SwiftSetting] {
        [
          .enableUpcomingFeature("TestCase")
        ]
      }
    }
    """

    let updatedManifest = SwiftSettings.updateContentsOfPackageManifest(input, with: SwiftSettings.testCaseSwiftSettings)
    XCTAssertEqual(updatedManifest, input)
  }

  @available(macOS 13.0, *)
  func testDoesNothingIfNoExistingExtension() {
    let input = """
    // swift-tools-version: 5.6
    import PackageDescription

    let package = Package(
      name: "MyPackage",
      targets: [.target(name: "MyTarget", swiftSettings: .airbnbDefault())])
    """

    let updatedManifest = SwiftSettings.updateContentsOfPackageManifest(input, with: SwiftSettings.testCaseSwiftSettings)
    XCTAssertEqual(updatedManifest, input)
  }

}
