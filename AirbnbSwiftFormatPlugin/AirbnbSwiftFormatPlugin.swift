import Foundation
import PackagePlugin

// MARK: - AirbnbSwiftFormatPlugin

/// A Swift Package Manager `CommandPlugin` that executes `AirbnbSwiftFormatTool`
/// to format source code in Swift package targets according to the Airbnb Swift Style Guide.
@main
struct AirbnbSwiftFormatPlugin: CommandPlugin {

  func performCommand(context: PluginContext, arguments: [String]) async throws {
    let process = Process()
    process.launchPath = try context.tool(named: "AirbnbSwiftFormatTool").path.string

    var processArguments = context.package.targets.map { $0.directory.string } + [
      "--swift-format-path",
      try context.tool(named: "swiftformat").path.string,
      "--swift-lint-path",
      try context.tool(named: "swiftlint").path.string,
      // The process we spawn doesn't have read/write access to the default
      // cache file locations, so we pass in our own cache paths from
      // the plugin's work directory.
      "--swift-format-cache-path",
      context.pluginWorkDirectory.string + "/swiftformat.cache",
      "--swift-lint-cache-path",
      context.pluginWorkDirectory.string + "/swiftlint.cache",
    ]

    if arguments.contains("--lint") {
      processArguments += ["--lint"]
    }

    process.arguments = processArguments
    try process.run()
    process.waitUntilExit()

    guard process.terminationStatus == 0 else {
      throw LintError.lintFailure
    }
  }

}

// MARK: - LintError

enum LintError: Error {
  case lintFailure
}
