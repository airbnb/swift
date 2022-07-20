import ArgumentParser
import Foundation

// MARK: - AirbnbSwiftFormatTool

/// A command line tool that formats the given directories using SwiftFormat and SwiftLint,
/// based on the Airbnb Swift Style Guide
@main
struct AirbnbSwiftFormatTool: ParsableCommand {

  // MARK: Internal

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

  @Option(help: "The absolute path to the SwiftFormat config file")
  var swiftFormatConfig = Bundle.module.path(forResource: "airbnb", ofType: "swiftformat")!

  @Option(help: "The absolute path to the SwiftLint config file")
  var swiftLintConfig = Bundle.module.path(forResource: "swiftlint", ofType: "yml")!

  mutating func run() throws {
    try swiftFormat.run()
    swiftFormat.waitUntilExit()

    try swiftLint.run()
    swiftLint.waitUntilExit()

    guard
      swiftFormat.terminationStatus == 0,
      swiftLint.terminationStatus == 0
    else {
      throw LintError.lintFailure
    }
  }

  // MARK: Private

  private lazy var swiftFormat: Process = {
    var arguments = directories + [
      "--config", swiftFormatConfig,
    ]

    if let swiftFormatCachePath = swiftFormatCachePath {
      arguments += ["--cache", swiftFormatCachePath]
    }

    if lint {
      arguments += ["--lint"]
    }

    let swiftFormat = Process()
    swiftFormat.launchPath = swiftFormatPath
    swiftFormat.arguments = arguments
    return swiftFormat
  }()

  private lazy var swiftLint: Process = {
    var arguments = directories + [
      "--config", swiftLintConfig,
      // Required for SwiftLint to emit a non-zero exit code on lint failure
      "--strict",
      // This flag is required when invoking SwiftLint from an SPM plugin, due to sandboxing
      "--in-process-sourcekit",
    ]

    if let swiftLintCachePath = swiftLintCachePath {
      arguments += ["--cache-path", swiftLintCachePath]
    }

    if !lint {
      arguments += ["--fix"]
    }

    let swiftLint = Process()
    swiftLint.launchPath = swiftLintPath
    swiftLint.arguments = arguments
    return swiftLint
  }()

}

// MARK: - LintError

enum LintError: Error {
  case lintFailure
}
