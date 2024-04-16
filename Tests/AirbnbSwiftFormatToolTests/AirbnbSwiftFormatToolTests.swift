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
        swiftFormat: { _ in
          ranSwiftFormat = true
          return EXIT_SUCCESS
        },
        swiftLint: { _ in
          ranSwiftLint = true
          return EXIT_SUCCESS
        },
        swiftLintAutocorrect: { _ in
          ranSwiftLintAutocorrect = true
          return EXIT_SUCCESS
        }))

    XCTAssertNil(error)
    XCTAssertTrue(ranSwiftFormat)
    XCTAssertTrue(ranSwiftLint)
    XCTAssertTrue(ranSwiftLintAutocorrect)
  }

  func testLintWithNoViolations() {
    var ranSwiftFormat = false
    var ranSwiftLint = false
    var ranSwiftLintAutocorrect = false

    let error = runFormatTool(
      arguments: ["--lint"],
      with: MockCommands(
        swiftFormat: { _ in
          ranSwiftFormat = true
          return EXIT_SUCCESS
        },
        swiftLint: { _ in
          ranSwiftLint = true
          return EXIT_SUCCESS
        },
        swiftLintAutocorrect: { _ in
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
        swiftFormat: { command in
          ranSwiftFormat = true

          // When autocorrecting, SwiftFormat returns EXIT_SUCCESS even if there were
          // violations that were fixed, unless you pass in the --strict option.
          if command.arguments.contains("--strict") {
            return SwiftFormatExitCode.lintFailure
          } else {
            return EXIT_SUCCESS
          }
        },
        swiftLint: { _ in
          ranSwiftLint = true
          return SwiftLintExitCode.lintFailure
        },
        swiftLintAutocorrect: { _ in
          ranSwiftLintAutocorrect = true

          // When autocorrecting SwiftLint returns EXIT_SUCCESS
          // even if there were violations that were fixed
          return EXIT_SUCCESS
        }))

    XCTAssertEqual(error as? ExitCode, .failure)
    XCTAssertTrue(ranSwiftFormat)
    XCTAssertTrue(ranSwiftLint)
    XCTAssertTrue(ranSwiftLintAutocorrect)
  }

  func testFormatWithOnlySwiftFormatViolation() {
    var ranSwiftFormat = false
    var ranSwiftLint = false
    var ranSwiftLintAutocorrect = false

    let error = runFormatTool(
      with: MockCommands(
        swiftFormat: { command in
          ranSwiftFormat = true

          // When autocorrecting, SwiftFormat returns EXIT_SUCCESS even if there were
          // violations that were fixed, unless you pass in the --strict option.
          if command.arguments.contains("--strict") {
            return SwiftFormatExitCode.lintFailure
          } else {
            return EXIT_SUCCESS
          }
        },
        swiftLint: { _ in
          ranSwiftLint = true
          return EXIT_SUCCESS
        },
        swiftLintAutocorrect: { _ in
          ranSwiftLintAutocorrect = true
          return EXIT_SUCCESS
        }))

    XCTAssertEqual(error as? ExitCode, .failure)
    XCTAssertTrue(ranSwiftFormat)
    XCTAssertTrue(ranSwiftLint)
    XCTAssertTrue(ranSwiftLintAutocorrect)
  }

  func testFormatWithOnlySwiftLintAutocorrectedViolation() {
    var ranSwiftFormat = false
    var ranSwiftLint = false
    var ranSwiftLintAutocorrect = false

    let error = runFormatTool(
      with: MockCommands(
        swiftFormat: { _ in
          ranSwiftFormat = true
          return EXIT_SUCCESS
        },
        swiftLint: { _ in
          ranSwiftLint = true

          // Assume that the codebase has violations that would be corrected by SwiftLint autocorrect.
          if ranSwiftLintAutocorrect {
            // If SwiftLint autocorrect has already run, then there are no more violations.
            // This is the expected behavior.
            return EXIT_SUCCESS
          } else {
            // If SwiftLint autocorrect hasn't run yet, then there are still violations.
            // This should not happen, because we run autocorrect first.
            return SwiftLintExitCode.lintFailure
          }
        },
        swiftLintAutocorrect: { _ in
          // Assume that this SwiftLint autocorrect invocation applied a code change.
          // In this case, SwiftLint still returns a zero exit code.
          ranSwiftLintAutocorrect = true
          return EXIT_SUCCESS
        }))

    // Even though there was a SwiftLint autocorrect violation,
    // SwiftLint always returns a zero exit code when autocorrecting.
    XCTAssertNil(error)

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
        swiftFormat: { _ in
          ranSwiftFormat = true
          return SwiftFormatExitCode.lintFailure
        },
        swiftLint: { _ in
          ranSwiftLint = true
          return SwiftLintExitCode.lintFailure
        },
        swiftLintAutocorrect: { _ in
          ranSwiftLintAutocorrect = true
          return EXIT_SUCCESS
        }))

    XCTAssertEqual(error as? ExitCode, .failure)
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
        swiftFormat: { _ in
          ranSwiftFormat = true
          return EXIT_SUCCESS
        },
        swiftLint: { _ in
          ranSwiftLint = true
          return SwiftLintExitCode.lintFailure
        },
        swiftLintAutocorrect: { _ in
          ranSwiftLintAutocorrect = true
          return EXIT_SUCCESS
        }))

    XCTAssertEqual(error as? ExitCode, .failure)
    XCTAssertTrue(ranSwiftFormat)
    XCTAssertTrue(ranSwiftLint)
    XCTAssertFalse(ranSwiftLintAutocorrect)
  }

  func testLintWithOnlySwiftFormatViolation() {
    var ranSwiftFormat = false
    var ranSwiftLint = false
    var ranSwiftLintAutocorrect = false

    let error = runFormatTool(
      arguments: ["--lint"],
      with: MockCommands(
        swiftFormat: { _ in
          ranSwiftFormat = true
          return SwiftFormatExitCode.lintFailure
        },
        swiftLint: { _ in
          ranSwiftLint = true
          return EXIT_SUCCESS
        },
        swiftLintAutocorrect: { _ in
          ranSwiftLintAutocorrect = true
          return EXIT_SUCCESS
        }))

    XCTAssertEqual(error as? ExitCode, .failure)
    XCTAssertTrue(ranSwiftFormat)
    XCTAssertTrue(ranSwiftLint)
    XCTAssertFalse(ranSwiftLintAutocorrect)
  }

  func testHandlesUnexpectedErrorCode() {
    let unexpectedSwiftFormatExitCode = runFormatTool(
      with: MockCommands(swiftFormat: { _ in 1234 }))

    let unexpectedSwiftLintExitCode = runFormatTool(
      with: MockCommands(swiftLint: { _ in 42 }))

    XCTAssertEqual(unexpectedSwiftFormatExitCode as? ExitCode, ExitCode(1234))
    XCTAssertEqual(unexpectedSwiftLintExitCode as? ExitCode, ExitCode(42))
  }

  // MARK: Private

  /// Runs `AirbnbSwiftFormatTool` with the `Command` calls mocked using the given mocks
  private func runFormatTool(arguments: [String]? = nil, with mocks: MockCommands) -> Error? {
    let existingRunCommandImplementation = Command.runCommand

    Command.runCommand = mocks.mockRunCommand(_:)
    defer { Command.runCommand = existingRunCommandImplementation }

    let formatTool = try! AirbnbSwiftFormatTool.parse([
      "Sources",
      "--swift-format-path",
      "airbnb.swiftformat",
      "--swift-lint-path",
      "swiftlint.yml",
    ] + (arguments ?? []))

    do {
      try formatTool.run()
      return nil
    } catch {
      return error
    }
  }

}

// MARK: - MockCommands

/// Mock implementations of the commands ran by `AirbnbSwiftFormatTool`
struct MockCommands {
  var swiftFormat: ((Command) -> Int32)?
  var swiftLint: ((Command) -> Int32)?
  var swiftLintAutocorrect: ((Command) -> Int32)?

  func mockRunCommand(_ command: Command) -> Int32 {
    if command.launchPath.lowercased().contains("swiftformat") {
      return swiftFormat?(command) ?? EXIT_SUCCESS
    }

    else if command.launchPath.lowercased().contains("swiftlint") {
      if command.arguments.contains("--fix") {
        return swiftLintAutocorrect?(command) ?? EXIT_SUCCESS
      } else {
        return swiftLint?(command) ?? EXIT_SUCCESS
      }
    }

    else {
      fatalError("Unexpected command: \(command)")
    }
  }
}
