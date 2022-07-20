import ArgumentParser
import Foundation

/// A command line tool that formats the given directories using SwiftFormat and SwiftLint,
/// based on the Airbnb Swift Style Guide
@main
struct AirbnbSwiftFormatTool: ParsableCommand {

  // MARK: Internal

  @Argument(help: "The directories to format")
  var directories: [String]

  @Option(help: "The abosolute path to a SwiftFormat binary")
  var swiftFormatPath: String

  @Option(help: "The path to use for SwiftFormat's cache")
  var swiftFormatCachePath: String?

  @Option(help: "The abosolute path to a SwiftLint binary")
  var swiftLintPath: String

  @Option(help: "The path to use for SwiftLint's cache")
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
