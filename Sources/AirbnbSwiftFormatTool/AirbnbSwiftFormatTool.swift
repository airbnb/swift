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

  @Flag(help: "When true, logs the commands that are executed")
  var log = false

  @Option(help: "The absolute path to the SwiftFormat config file")
  var swiftFormatConfig = Bundle.module.path(forResource: "airbnb", ofType: "swiftformat")!

  @Option(help: "The absolute path to the SwiftLint config file")
  var swiftLintConfig = Bundle.module.path(forResource: "swiftlint", ofType: "yml")!

  @Option(help: "The project's minimum Swift version")
  var swiftVersion: String?

  func run() throws {
    let swiftFormat = makeSwiftFormatCommand()
    let swiftLint = makeSwiftLintCommand(autocorrect: false)
    let swiftLintAutocorrect = makeSwiftLintCommand(autocorrect: true)

    let swiftFormatExitCode = try swiftFormat.run()

    // Run SwiftLint in autocorrect mode first, so that if autocorrect fixes all of the SwiftLint violations
    // then the following lint-only invocation will not report any violations.
    let swiftLintAutocorrectExitCode: Int32?
    if
      // When only linting, we shouldn't run SwiftLint with autocorrect enabled
      !lintOnly
    {
      swiftLintAutocorrectExitCode = try swiftLintAutocorrect.run()
    } else {
      swiftLintAutocorrectExitCode = nil
    }

    // We always have to run SwiftLint in lint-only mode at least once,
    // because when in autocorrect mode SwiftLint won't emit any lint warnings.
    let swiftLintExitCode = try swiftLint.run()

    if
      swiftFormatExitCode == SwiftFormatExitCode.lintFailure ||
      swiftLintExitCode == SwiftLintExitCode.lintFailure ||
      swiftLintAutocorrectExitCode == SwiftLintExitCode.lintFailure
    {
      throw ExitCode.failure
    }

    // Any other non-success exit code is an unknown failure
    if swiftFormatExitCode != EXIT_SUCCESS {
      throw ExitCode(swiftFormatExitCode)
    }

    if swiftLintExitCode != EXIT_SUCCESS {
      throw ExitCode(swiftLintExitCode)
    }

    if
      let swiftLintAutocorrectExitCode = swiftLintAutocorrectExitCode,
      swiftLintAutocorrectExitCode != EXIT_SUCCESS
    {
      throw ExitCode(swiftLintAutocorrectExitCode)
    }
  }

  // MARK: Private

  /// Whether the command should autocorrect invalid code, or only emit lint errors
  private var lintOnly: Bool {
    lint
  }

  /// Builds a command that runs the SwiftFormat tool
  private func makeSwiftFormatCommand() -> Command {
    var arguments = directories + [
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

  /// Builds a command that runs the SwiftLint tool
  ///  - If `autocorrect` is true, passes the `--fix` flag to SwiftLint.
  ///    When autocorrecting, SwiftLint doesn't emit any lint warnings.
  private func makeSwiftLintCommand(autocorrect: Bool) -> Command {
    var arguments = directories + [
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
