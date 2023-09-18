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

// MARK: - SwiftSettingsTests

@available(macOS 13.0, *)
final class SwiftSettingsTests: XCTestCase {

  func testCanUseRegexLiterals() {
    // Verifying that this module can use regex literals,
    // meaning that the Swift Settings are applied correctly.
    // (In Swift 5.x this does not compile successfully by default)
    let regex = /Check it out .+, I'm a (regex|REGEX) literal!/
    XCTAssert("Check it out mom, I'm a regex literal!".contains(regex))
    XCTAssert("Check it out dad, I'm a REGEX literal!".contains(regex))
  }

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
