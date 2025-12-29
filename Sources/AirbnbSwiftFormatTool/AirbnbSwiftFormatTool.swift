import ArgumentParser
import Foundation

// MARK: - AirbnbSwiftFormatTool

/// A command line tool that formats the given directories using SwiftFormat and SwiftLint,
/// based on the Airbnb Swift Style Guide
@main
struct AirbnbSwiftFormatTool: AsyncParsableCommand {

  // MARK: Internal

  /// This property can be overridden to provide a mock implementation in unit tests.
  static var checkForSwiftFiles: (String) -> Bool = defaultCheckForSwiftFiles

  @Argument(help: "The directories to format")
  var directories: [String]

  @Option(help: "The absolute path to a SwiftFormat binary")
  var swiftFormatPath: String

  @Option(help: "The absolute path to use for SwiftFormat's cache")
  var swiftFormatCachePath: String?

  @Option(help: "The absolute path to a SwiftLint binary")
  var swiftLintPath: String

  @Option(help: "The absolute path to use for SwiftLint's cache")
  var swiftLintCachePath: String?

  @Flag(help: "When true, source files are not reformatted")
  var lint = false

  @Flag(help: "When true, logs the commands that are executed")
  var log = false

  @Option(help: "The absolute path to the SwiftFormat config file")
  var swiftFormatConfig = Bundle.module.path(forResource: "airbnb", ofType: "swiftformat")!

  @Option(help: "The absolute path to the SwiftLint config file")
  var swiftLintConfig = Bundle.module.path(forResource: "swiftlint", ofType: "yml")!

  @Option(help: "The project's minimum Swift version")
  var swiftVersion: String?

  func run() async throws {
    // Process all directories in parallel, each running the full pipeline independently.
    // We use withTaskGroup (not withThrowingTaskGroup) to ensure ALL directories are processed
    // even if some fail - this gives users complete feedback about all issues.
    let results = await withTaskGroup(of: Result<DirectoryResult, Error>.self) { group in
      for directory in directories {
        group.addTask {
          do {
            return .success(try await processDirectory(directory))
          } catch {
            return .failure(DirectoryError(directory: directory, underlyingError: error))
          }
        }
      }

      var results = [Result<DirectoryResult, Error>]()
      for await result in group {
        results.append(result)
      }
      return results
    }

    try aggregateResults(results)
  }

  // MARK: Private

  /// Whether the command should autocorrect invalid code, or only emit lint errors
  private var lintOnly: Bool {
    lint
  }

  /// Default implementation that checks if a directory (or file) contains any Swift files
  ///  - For a .swift file path, returns true
  ///  - For a directory, recursively checks for .swift files
  private static func defaultCheckForSwiftFiles(_ path: String) -> Bool {
    let fileManager = FileManager.default
    var isDirectory: ObjCBool = false

    guard fileManager.fileExists(atPath: path, isDirectory: &isDirectory) else {
      return false
    }

    // If it's a Swift file directly, return true
    if !isDirectory.boolValue {
      return path.hasSuffix(".swift")
    }

    // For directories, check for any .swift files recursively
    guard let enumerator = fileManager.enumerator(atPath: path) else {
      return false
    }

    for case let file as String in enumerator {
      if file.hasSuffix(".swift") {
        return true
      }
    }

    return false
  }

  /// Processes a single directory through the full formatting pipeline
  ///  - SwiftFormat -> SwiftLint autocorrect (if not lint-only) -> SwiftLint lint
  private func processDirectory(_ directory: String) async throws -> DirectoryResult {
    // Skip directories that contain no Swift files to avoid SwiftLint's
    // "no lintable files found" error (exit code 1)
    guard Self.checkForSwiftFiles(directory) else {
      log("Skipping '\(directory)' (no Swift files found)")
      return DirectoryResult(
        directory: directory,
        swiftFormatExitCode: EXIT_SUCCESS,
        swiftLintExitCode: EXIT_SUCCESS,
        swiftLintAutocorrectExitCode: lintOnly ? nil : EXIT_SUCCESS
      )
    }

    let swiftFormatExitCode = try await makeSwiftFormatCommand(for: directory).runAsync()

    // Run SwiftLint in autocorrect mode first, so that if autocorrect fixes all of the SwiftLint violations
    // then the following lint-only invocation will not report any violations.
    let swiftLintAutocorrectExitCode: Int32?
    if !lintOnly {
      swiftLintAutocorrectExitCode = try await makeSwiftLintCommand(for: directory, autocorrect: true).runAsync()
    } else {
      swiftLintAutocorrectExitCode = nil
    }

    // We always have to run SwiftLint in lint-only mode at least once,
    // because when in autocorrect mode SwiftLint won't emit any lint warnings.
    let swiftLintExitCode = try await makeSwiftLintCommand(for: directory, autocorrect: false).runAsync()

    return DirectoryResult(
      directory: directory,
      swiftFormatExitCode: swiftFormatExitCode,
      swiftLintExitCode: swiftLintExitCode,
      swiftLintAutocorrectExitCode: swiftLintAutocorrectExitCode
    )
  }

  /// Aggregates results from all directories and throws appropriate errors
  private func aggregateResults(_ results: [Result<DirectoryResult, Error>]) throws {
    var successResults = [DirectoryResult]()
    var executionErrors = [DirectoryError]()

    // Separate successes from execution errors
    for result in results {
      switch result {
      case .success(let directoryResult):
        successResults.append(directoryResult)
      case .failure(let error):
        if let directoryError = error as? DirectoryError {
          executionErrors.append(directoryError)
        } else {
          // Defensive: wrap unexpected error types to avoid silent failures
          executionErrors.append(DirectoryError(directory: "unknown", underlyingError: error))
        }
      }
    }

    // Report any execution errors (e.g., binary not found)
    if let firstError = executionErrors.first {
      for error in executionErrors {
        log("Failed to process '\(error.directory)': \(error.underlyingError.localizedDescription)")
      }
      throw firstError.underlyingError
    }

    // Check for lint failures and report which directories had issues
    var directoriesWithLintFailures = [String]()
    for result in successResults {
      if
        result.swiftFormatExitCode == SwiftFormatExitCode.lintFailure ||
        result.swiftLintExitCode == SwiftLintExitCode.lintFailure ||
        result.swiftLintAutocorrectExitCode == SwiftLintExitCode.lintFailure
      {
        directoriesWithLintFailures.append(result.directory)
      }
    }

    if !directoriesWithLintFailures.isEmpty {
      log("Lint failures in: \(directoriesWithLintFailures.joined(separator: ", "))")
      throw ExitCode.failure
    }

    // Any other non-success exit code is an unknown failure
    for result in successResults {
      if result.swiftFormatExitCode != EXIT_SUCCESS {
        log("SwiftFormat failed in '\(result.directory)' with exit code \(result.swiftFormatExitCode)")
        throw ExitCode(result.swiftFormatExitCode)
      }

      if result.swiftLintExitCode != EXIT_SUCCESS {
        log("SwiftLint failed in '\(result.directory)' with exit code \(result.swiftLintExitCode)")
        throw ExitCode(result.swiftLintExitCode)
      }

      if
        let swiftLintAutocorrectExitCode = result.swiftLintAutocorrectExitCode,
        swiftLintAutocorrectExitCode != EXIT_SUCCESS
      {
        log("SwiftLint autocorrect failed in '\(result.directory)' with exit code \(swiftLintAutocorrectExitCode)")
        throw ExitCode(swiftLintAutocorrectExitCode)
      }
    }
  }

  /// Builds a command that runs the SwiftFormat tool on a single directory
  private func makeSwiftFormatCommand(for directory: String) -> Command {
    var arguments = [directory] + [
      "--config",
      swiftFormatConfig,
    ]

    if let swiftFormatCachePath = swiftFormatCachePath {
      arguments += ["--cache", swiftFormatCachePath]
    }

    if lint {
      arguments += ["--lint"]
    }

    if let swiftVersion = swiftVersion {
      arguments += ["--swiftversion", swiftVersion]
    }

    return Command(
      log: log,
      launchPath: swiftFormatPath,
      arguments: arguments
    )
  }

  /// Builds a command that runs the SwiftLint tool on a single directory
  ///  - If `autocorrect` is true, passes the `--fix` flag to SwiftLint.
  ///    When autocorrecting, SwiftLint doesn't emit any lint warnings.
  private func makeSwiftLintCommand(for directory: String, autocorrect: Bool) -> Command {
    var arguments = [directory] + [
      "--config",
      swiftLintConfig,
      // Required for SwiftLint to emit a non-zero exit code on lint failure
      "--strict",
    ]

    if let swiftLintCachePath = swiftLintCachePath {
      arguments += ["--cache-path", swiftLintCachePath]
    }

    if autocorrect {
      arguments += ["--fix"]
    }

    return Command(
      log: log,
      launchPath: swiftLintPath,
      arguments: arguments
    )
  }

  private func log(_ string: String) {
    // swiftlint:disable:next no_direct_standard_out_logs
    print("[AirbnbSwiftFormatTool]", string)
  }

}

extension Process {
  var shellCommand: String {
    let launchPath = launchPath ?? ""
    let arguments = arguments ?? []
    return "\(launchPath) \(arguments.joined(separator: " "))"
  }
}

// MARK: - SwiftFormatExitCode

/// Known exit codes used by SwiftFormat
enum SwiftFormatExitCode {
  static let lintFailure: Int32 = 1
}

// MARK: - SwiftLintExitCode

/// Known exit codes used by SwiftLint
enum SwiftLintExitCode {
  static let lintFailure: Int32 = 2
}

// MARK: - DirectoryResult

/// The result of running the formatting pipeline on a single directory
struct DirectoryResult: Sendable {
  let directory: String
  let swiftFormatExitCode: Int32
  let swiftLintExitCode: Int32
  let swiftLintAutocorrectExitCode: Int32?
}

// MARK: - DirectoryError

/// An error that occurred while processing a specific directory
struct DirectoryError: Error {
  let directory: String
  let underlyingError: Error
}
