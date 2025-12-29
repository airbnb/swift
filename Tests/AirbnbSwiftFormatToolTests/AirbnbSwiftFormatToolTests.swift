// Created by Cal Stephens on 9/25/23.
// Copyright © 2023 Airbnb Inc. All rights reserved.

import ArgumentParser
import XCTest

@testable import AirbnbSwiftFormatTool

// MARK: - AirbnbSwiftFormatToolTest

final class AirbnbSwiftFormatToolTest: XCTestCase {

  // MARK: Internal

  func testFormatWithNoViolations() async {
    var ranSwiftFormat = false
    var ranSwiftLint = false
    var ranSwiftLintAutocorrect = false

    let error = await runFormatTool(
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
        }
      )
    )

    XCTAssertNil(error)
    XCTAssertTrue(ranSwiftFormat)
    XCTAssertTrue(ranSwiftLint)
    XCTAssertTrue(ranSwiftLintAutocorrect)
  }

  func testLintWithNoViolations() async {
    var ranSwiftFormat = false
    var ranSwiftLint = false
    var ranSwiftLintAutocorrect = false

    let error = await runFormatTool(
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
        }
      )
    )

    XCTAssertNil(error)
    XCTAssertTrue(ranSwiftFormat)
    XCTAssertTrue(ranSwiftLint)

    // Should't run SwiftLint autocorrect in lint-only mode
    XCTAssertFalse(ranSwiftLintAutocorrect)
  }

  func testFormatWithViolations() async {
    var ranSwiftFormat = false
    var ranSwiftLint = false
    var ranSwiftLintAutocorrect = false

    let error = await runFormatTool(
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
        }
      )
    )

    XCTAssertEqual(error as? ExitCode, ExitCode(SwiftFormatExitCode.lintFailure))
    XCTAssertTrue(ranSwiftFormat)
    XCTAssertTrue(ranSwiftLint)
    XCTAssertTrue(ranSwiftLintAutocorrect)
  }

  func testFormatWithOnlySwiftLintAutocorrectedViolation() async {
    var ranSwiftFormat = false
    var ranSwiftLint = false
    var ranSwiftLintAutocorrect = false

    let error = await runFormatTool(
      with: MockCommands(
        swiftFormat: {
          ranSwiftFormat = true
          return EXIT_SUCCESS
        },
        swiftLint: {
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
        swiftLintAutocorrect: {
          // Assume that this SwiftLint autocorrect invocation applied a code change.
          // In this case, SwiftLint still returns a zero exit code.
          ranSwiftLintAutocorrect = true
          return EXIT_SUCCESS
        }
      )
    )

    // Even though there was a SwiftLint failure, it was autocorrected so doesn't require attention.
    // The tool should not return an error (e.g. it should return a zero exit code).
    XCTAssertNil(error)

    XCTAssertTrue(ranSwiftFormat)
    XCTAssertTrue(ranSwiftLint)
    XCTAssertTrue(ranSwiftLintAutocorrect)
  }

  func testLintWithViolations() async {
    var ranSwiftFormat = false
    var ranSwiftLint = false
    var ranSwiftLintAutocorrect = false

    let error = await runFormatTool(
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
        }
      )
    )

    XCTAssertEqual(error as? ExitCode, ExitCode.failure)
    XCTAssertTrue(ranSwiftFormat)
    XCTAssertTrue(ranSwiftLint)
    XCTAssertFalse(ranSwiftLintAutocorrect)
  }

  func testLintWithOnlySwiftLintViolation() async {
    var ranSwiftFormat = false
    var ranSwiftLint = false
    var ranSwiftLintAutocorrect = false

    let error = await runFormatTool(
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
        }
      )
    )

    XCTAssertEqual(error as? ExitCode, ExitCode.failure)
    XCTAssertTrue(ranSwiftFormat)
    XCTAssertTrue(ranSwiftLint)
    XCTAssertFalse(ranSwiftLintAutocorrect)
  }

  func testLintWithOnlySwiftFormatViolation() async {
    var ranSwiftFormat = false
    var ranSwiftLint = false
    var ranSwiftLintAutocorrect = false

    let error = await runFormatTool(
      arguments: ["--lint"],
      with: MockCommands(
        swiftFormat: {
          ranSwiftFormat = true
          return SwiftFormatExitCode.lintFailure
        },
        swiftLint: {
          ranSwiftLint = true
          return EXIT_SUCCESS
        },
        swiftLintAutocorrect: {
          ranSwiftLintAutocorrect = true
          return EXIT_SUCCESS
        }
      )
    )

    XCTAssertEqual(error as? ExitCode, ExitCode.failure)
    XCTAssertTrue(ranSwiftFormat)
    XCTAssertTrue(ranSwiftLint)
    XCTAssertFalse(ranSwiftLintAutocorrect)
  }

  func testHandlesUnexpectedErrorCode() async {
    let unexpectedSwiftFormatExitCode = await runFormatTool(
      with: MockCommands(swiftFormat: { 1234 })
    )

    let unexpectedSwiftLintExitCode = await runFormatTool(
      with: MockCommands(swiftLint: { 42 })
    )

    XCTAssertEqual(unexpectedSwiftFormatExitCode as? ExitCode, ExitCode(1234))
    XCTAssertEqual(unexpectedSwiftLintExitCode as? ExitCode, ExitCode(42))
  }

  func testParallelDirectoryProcessing() async {
    let lock = NSLock()
    var processedDirectories = Set<String>()

    let error = await runFormatTool(
      directories: ["DirA", "DirB", "DirC"],
      with: MockCommands(
        swiftFormatHandler: { command in
          let directory = command.arguments.first ?? ""
          lock.lock()
          processedDirectories.insert(directory)
          lock.unlock()
          return EXIT_SUCCESS
        },
        swiftLintHandler: { _ in EXIT_SUCCESS },
        swiftLintAutocorrectHandler: { _ in EXIT_SUCCESS }
      )
    )

    XCTAssertNil(error)
    XCTAssertEqual(processedDirectories, ["DirA", "DirB", "DirC"])
  }

  func testParallelDirectoryProcessing_allDirectoriesProcessedEvenWhenOneFails() async {
    let lock = NSLock()
    var processedDirectories = Set<String>()

    let error = await runFormatTool(
      directories: ["DirA", "DirB", "DirC"],
      with: MockCommands(
        swiftFormatHandler: { command in
          let directory = command.arguments.first ?? ""
          lock.lock()
          processedDirectories.insert(directory)
          lock.unlock()
          return EXIT_SUCCESS
        },
        swiftLintHandler: { command in
          let directory = command.arguments.first ?? ""
          // Only DirB has lint failures
          return directory == "DirB" ? SwiftLintExitCode.lintFailure : EXIT_SUCCESS
        },
        swiftLintAutocorrectHandler: { _ in EXIT_SUCCESS }
      )
    )

    // Should fail due to lint failure in DirB
    XCTAssertEqual(error as? ExitCode, ExitCode.failure)
    // All directories should still have been processed (not cancelled early)
    XCTAssertEqual(processedDirectories, ["DirA", "DirB", "DirC"])
  }

  func testParallelDirectoryProcessing_multipleDirectoriesWithLintFailures() async {
    let lock = NSLock()
    var processedDirectories = Set<String>()

    let error = await runFormatTool(
      directories: ["DirA", "DirB", "DirC"],
      with: MockCommands(
        swiftFormatHandler: { command in
          let directory = command.arguments.first ?? ""
          lock.lock()
          processedDirectories.insert(directory)
          lock.unlock()
          return EXIT_SUCCESS
        },
        swiftLintHandler: { command in
          let directory = command.arguments.first ?? ""
          // DirA and DirC have lint failures, DirB succeeds
          return directory == "DirB" ? EXIT_SUCCESS : SwiftLintExitCode.lintFailure
        },
        swiftLintAutocorrectHandler: { _ in EXIT_SUCCESS }
      )
    )

    // Should fail due to lint failures
    XCTAssertEqual(error as? ExitCode, ExitCode.failure)
    // All directories should still have been processed
    XCTAssertEqual(processedDirectories, ["DirA", "DirB", "DirC"])
  }

  func testParallelDirectoryProcessing_unexpectedExitCodeInOneDirectory() async {
    let lock = NSLock()
    var processedDirectories = Set<String>()

    let error = await runFormatTool(
      directories: ["DirA", "DirB"],
      with: MockCommands(
        swiftFormatHandler: { command in
          let directory = command.arguments.first ?? ""
          lock.lock()
          processedDirectories.insert(directory)
          lock.unlock()
          // DirB returns unexpected exit code
          return directory == "DirB" ? 99 : EXIT_SUCCESS
        },
        swiftLintHandler: { _ in EXIT_SUCCESS },
        swiftLintAutocorrectHandler: { _ in EXIT_SUCCESS }
      )
    )

    // Should fail with the unexpected exit code
    XCTAssertEqual(error as? ExitCode, ExitCode(99))
    // Both directories should have been processed
    XCTAssertEqual(processedDirectories, ["DirA", "DirB"])
  }

  func testEmptyDirectoryIsSkipped() async {
    var ranSwiftFormat = false
    var ranSwiftLint = false
    var ranSwiftLintAutocorrect = false

    let error = await runFormatTool(
      directories: ["EmptyDir"],
      swiftFilesCheck: { _ in false },
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
        }
      )
    )

    // Should succeed (empty directories are not an error)
    XCTAssertNil(error)
    // No tools should have been run on an empty directory
    XCTAssertFalse(ranSwiftFormat)
    XCTAssertFalse(ranSwiftLint)
    XCTAssertFalse(ranSwiftLintAutocorrect)
  }

  func testMixedEmptyAndNonEmptyDirectories() async {
    let lock = NSLock()
    var processedDirectories = Set<String>()

    let error = await runFormatTool(
      directories: ["Sources", "EmptyDir", "Tests"],
      swiftFilesCheck: { directory in
        // Only Sources and Tests have Swift files
        directory != "EmptyDir"
      },
      with: MockCommands(
        swiftFormatHandler: { command in
          let directory = command.arguments.first ?? ""
          lock.lock()
          processedDirectories.insert(directory)
          lock.unlock()
          return EXIT_SUCCESS
        },
        swiftLintHandler: { _ in EXIT_SUCCESS },
        swiftLintAutocorrectHandler: { _ in EXIT_SUCCESS }
      )
    )

    XCTAssertNil(error)
    // Only non-empty directories should have been processed
    XCTAssertEqual(processedDirectories, ["Sources", "Tests"])
  }

  func testEmptyDirectoryWithLintMode() async {
    var ranSwiftFormat = false
    var ranSwiftLint = false
    var ranSwiftLintAutocorrect = false

    let error = await runFormatTool(
      arguments: ["--lint"],
      directories: ["EmptyDir"],
      swiftFilesCheck: { _ in false },
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
        }
      )
    )

    // Should succeed in lint mode too
    XCTAssertNil(error)
    XCTAssertFalse(ranSwiftFormat)
    XCTAssertFalse(ranSwiftLint)
    XCTAssertFalse(ranSwiftLintAutocorrect)
  }

  // MARK: Private

  /// Runs `AirbnbSwiftFormatTool` with the `Command` calls mocked using the given mocks
  private func runFormatTool(
    arguments: [String]? = nil,
    directories: [String] = ["Sources"],
    swiftFilesCheck: ((String) -> Bool)? = nil,
    with mocks: MockCommands
  ) async -> Error? {
    let existingRunCommandImplementation = Command.runCommand
    let existingSwiftFilesCheck = AirbnbSwiftFormatTool.checkForSwiftFiles

    Command.runCommand = mocks.mockRunCommand(_:)
    AirbnbSwiftFormatTool.checkForSwiftFiles = swiftFilesCheck ?? { _ in true }
    defer {
      Command.runCommand = existingRunCommandImplementation
      AirbnbSwiftFormatTool.checkForSwiftFiles = existingSwiftFilesCheck
    }

    let formatTool = try! AirbnbSwiftFormatTool.parse(
      directories + [
        "--swift-format-path",
        "airbnb.swiftformat",
        "--swift-lint-path",
        "swiftlint.yml",
      ] + (arguments ?? [])
    )

    do {
      try await formatTool.run()
      return nil
    } catch {
      return error
    }
  }

}

// MARK: - MockCommands

/// Mock implementations of the commands ran by `AirbnbSwiftFormatTool`
struct MockCommands {

  // MARK: Lifecycle

  /// Convenience initializer for simple mocks that don't need command details
  init(
    swiftFormat: (() -> Int32)? = nil,
    swiftLint: (() -> Int32)? = nil,
    swiftLintAutocorrect: (() -> Int32)? = nil
  ) {
    swiftFormatHandler = swiftFormat.map { closure in { _ in closure() } }
    swiftLintHandler = swiftLint.map { closure in { _ in closure() } }
    swiftLintAutocorrectHandler = swiftLintAutocorrect.map { closure in { _ in closure() } }
  }

  /// Initializer for mocks that need access to command details (e.g., directory)
  init(
    swiftFormatHandler: ((Command) -> Int32)? = nil,
    swiftLintHandler: ((Command) -> Int32)? = nil,
    swiftLintAutocorrectHandler: ((Command) -> Int32)? = nil
  ) {
    self.swiftFormatHandler = swiftFormatHandler
    self.swiftLintHandler = swiftLintHandler
    self.swiftLintAutocorrectHandler = swiftLintAutocorrectHandler
  }

  // MARK: Internal

  var swiftFormatHandler: ((Command) -> Int32)?
  var swiftLintHandler: ((Command) -> Int32)?
  var swiftLintAutocorrectHandler: ((Command) -> Int32)?

  func mockRunCommand(_ command: Command) -> Int32 {
    if command.launchPath.lowercased().contains("swiftformat") {
      return swiftFormatHandler?(command) ?? EXIT_SUCCESS
    }

    else if command.launchPath.lowercased().contains("swiftlint") {
      if command.arguments.contains("--fix") {
        return swiftLintAutocorrectHandler?(command) ?? EXIT_SUCCESS
      } else {
        return swiftLintHandler?(command) ?? EXIT_SUCCESS
      }
    }

    else {
      fatalError("Unexpected command: \(command)")
    }
  }
}
