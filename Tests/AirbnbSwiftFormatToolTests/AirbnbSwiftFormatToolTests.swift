// Created by Cal Stephens on 9/25/23.
// Copyright © 2023 Airbnb Inc. All rights reserved.

import ArgumentParser
import XCTest

@testable import AirbnbSwiftFormatTool

// MARK: - AirbnbSwiftFormatToolTest

final class AirbnbSwiftFormatToolTest: XCTestCase {

  // MARK: Internal

  func testFormatWithNoViolations() {
    var ranSwiftFormat = false
    var ranSwiftLint = false
    var ranSwiftLintAutocorrect = false

    let error = runFormatTool(
      with: MockCommands(
        swiftFormat: {
          ranSwiftFormat = true
          return EXIT_SUCCESS
        },
        swiftLint: {
          ranSwiftLint = true
          return EXIT_SUCCESS
        },
        swiftLintAutocorrect: {
          ranSwiftLintAutocorrect = true
          return EXIT_SUCCESS
        }))

    XCTAssertNil(error)
    XCTAssertTrue(ranSwiftFormat)
    XCTAssertTrue(ranSwiftLint)

    // No need to run SwiftLint autocorrect if there were no violations
    XCTAssertFalse(ranSwiftLintAutocorrect)
  }

  func testLintWithNoViolations() {
    var ranSwiftFormat = false
    var ranSwiftLint = false
    var ranSwiftLintAutocorrect = false

    let error = runFormatTool(
      arguments: ["--lint"],
      with: MockCommands(
        swiftFormat: {
          ranSwiftFormat = true
          return EXIT_SUCCESS
        },
        swiftLint: {
          ranSwiftLint = true
          return EXIT_SUCCESS
        },
        swiftLintAutocorrect: {
          ranSwiftLintAutocorrect = true
          return EXIT_SUCCESS
        }))

    XCTAssertNil(error)
    XCTAssertTrue(ranSwiftFormat)
    XCTAssertTrue(ranSwiftLint)

    // Should't run SwiftLint autocorrect in lint-only mode
    XCTAssertFalse(ranSwiftLintAutocorrect)
  }

  func testFormatWithViolations() {
    var ranSwiftFormat = false
    var ranSwiftLint = false
    var ranSwiftLintAutocorrect = false

    let error = runFormatTool(
      with: MockCommands(
        swiftFormat: {
          ranSwiftFormat = true

          // When autocorrecting SwiftFormat returns EXIT_SUCCESS
          // even if there were violations that were fixed
          return EXIT_SUCCESS
        },
        swiftLint: {
          ranSwiftLint = true
          return SwiftLintExitCode.lintFailure
        },
        swiftLintAutocorrect: {
          ranSwiftLintAutocorrect = true

          // When autocorrecting SwiftLint returns EXIT_SUCCESS
          // even if there were violations that were fixed
          return EXIT_SUCCESS
        }))

    XCTAssertEqual(error as? ExitCode, ExitCode(SwiftFormatExitCode.lintFailure))
    XCTAssertTrue(ranSwiftFormat)
    XCTAssertTrue(ranSwiftLint)
    XCTAssertTrue(ranSwiftLintAutocorrect)
  }

  func testLintWithViolations() {
    var ranSwiftFormat = false
    var ranSwiftLint = false
    var ranSwiftLintAutocorrect = false

    let error = runFormatTool(
      arguments: ["--lint"],
      with: MockCommands(
        swiftFormat: {
          ranSwiftFormat = true
          return SwiftFormatExitCode.lintFailure
        },
        swiftLint: {
          ranSwiftLint = true
          return SwiftLintExitCode.lintFailure
        },
        swiftLintAutocorrect: {
          ranSwiftLintAutocorrect = true
          return EXIT_SUCCESS
        }))

    XCTAssertEqual(error as? ExitCode, ExitCode.failure)
    XCTAssertTrue(ranSwiftFormat)
    XCTAssertTrue(ranSwiftLint)
    XCTAssertFalse(ranSwiftLintAutocorrect)
  }

  func testLintWithOnlySwiftLintViolation() {
    var ranSwiftFormat = false
    var ranSwiftLint = false
    var ranSwiftLintAutocorrect = false

    let error = runFormatTool(
      arguments: ["--lint"],
      with: MockCommands(
        swiftFormat: {
          ranSwiftFormat = true
          return EXIT_SUCCESS
        },
        swiftLint: {
          ranSwiftLint = true
          return SwiftLintExitCode.lintFailure
        },
        swiftLintAutocorrect: {
          ranSwiftLintAutocorrect = true
          return EXIT_SUCCESS
        }))

    XCTAssertEqual(error as? ExitCode, ExitCode.failure)
    XCTAssertTrue(ranSwiftFormat)
    XCTAssertTrue(ranSwiftLint)
    XCTAssertFalse(ranSwiftLintAutocorrect)
  }

  func testHandlesUnexpectedErrorCode() {
    let unexpectedSwiftFormatExitCode = runFormatTool(
      with: MockCommands(swiftFormat: { 1234 }))

    let unexpectedSwiftLintExitCode = runFormatTool(
      with: MockCommands(swiftLint: { 42 }))

    XCTAssertEqual(unexpectedSwiftFormatExitCode as? ExitCode, ExitCode(1234))
    XCTAssertEqual(unexpectedSwiftLintExitCode as? ExitCode, ExitCode(42))
  }

  // MARK: Private

  /// Runs `AirbnbSwiftFormatTool` with the `Command` calls mocked using the given mocks
  private func runFormatTool(arguments: [String]? = nil, with mocks: MockCommands) -> Error? {
    let formatTool = try! AirbnbSwiftFormatTool.parse([
      "Sources",
      "--swift-format-path",
      "airbnb.swiftformat",
      "--swift-lint-path",
      "swiftlint.yml",
    ] + (arguments ?? []))

    do {
      try formatTool.run(executeCommand: mocks.mockRunCommand(_:))
      return nil
    } catch {
      return error
    }
  }

}

// MARK: - MockCommands

/// Mock implementations of the commands ran by `AirbnbSwiftFormatTool`
struct MockCommands {
  var swiftFormat: (() -> Int32)?
  var swiftLint: (() -> Int32)?
  var swiftLintAutocorrect: (() -> Int32)?

  func mockRunCommand(_ command: Command) -> Int32 {
    if command.launchPath.lowercased().contains("swiftformat") {
      return swiftFormat?() ?? EXIT_SUCCESS
    }

    else if command.launchPath.lowercased().contains("swiftlint") {
      if command.arguments.contains("--fix") {
        return swiftLintAutocorrect?() ?? EXIT_SUCCESS
      } else {
        return swiftLint?() ?? EXIT_SUCCESS
      }
    }

    else {
      fatalError("Unexpected command: \(command)")
    }
  }
}
