import Foundation
import PackagePlugin

// MARK: - AirbnbSwiftFormatPlugin

/// A Swift Package Manager `CommandPlugin` that executes `AirbnbSwiftFormatTool`
/// to format source code in Swift package targets according to the Airbnb Swift Style Guide.
@main
struct AirbnbSwiftFormatPlugin: CommandPlugin {

  // MARK: Internal

  func performCommand(context: PluginContext, arguments: [String]) async throws {
    let process = Process()
    process.launchPath = try context.tool(named: "AirbnbSwiftFormatTool").path.string

    var argumentExtractor = ArgumentExtractor(arguments)

    let inputPaths = try inputPaths(
      context: context,
      // Consumers can exclude additional subdirectories with an `--exclude` flag
      excluding: argumentExtractor.extractOption(named: "exclude"))

    var processArguments = inputPaths + [
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

    // Pass any remaining arguments directly to the child process
    processArguments += argumentExtractor.remainingArguments

    process.arguments = processArguments
    try process.run()
    process.waitUntilExit()

    switch process.terminationStatus {
    case EXIT_SUCCESS:
      break
    case EXIT_FAILURE:
      throw Error.lintFailure
    default:
      throw Error.unknownError(exitCode: Int(process.terminationStatus))
    }
  }

  // MARK: Private

  /// Retrieves the list of paths that should be formatted / linted
  ///
  /// By default this tool runs on all subdirectories of the package's root directory,
  /// plus any Swift files directly contained in the root directory. This is a
  /// workaround for two interesting issues:
  ///  - If we lint `content.package.directory`, then SwiftLint lints the `.build` subdirectory,
  ///    which includes checkouts for any SPM dependencies, even if we add `.build` to the
  ///    `excluded` configuration in our `swiftlint.yml`.
  ///  - We could lint `context.package.targets.map { $0.directory }`, but that excludes
  ///    plugin targets, which include Swift code that we want to lint.
  private func inputPaths(context: PluginContext, excluding subfoldersToExclude: [String]) throws -> [String] {
    let packageDirectoryContents = try FileManager.default.contentsOfDirectory(
      at: URL(fileURLWithPath: context.package.directory.string),
      includingPropertiesForKeys: nil,
      options: [.skipsHiddenFiles])

    let subdirectories = packageDirectoryContents.filter { $0.hasDirectoryPath }
    let rootSwiftFiles = packageDirectoryContents.filter { $0.pathExtension.hasSuffix("swift") }

    return (subdirectories + rootSwiftFiles)
      .map { $0.path }
      // Filter out any directories included in the `--exclude` option
      .filter { path in
        for subfoldersToExclude in subfoldersToExclude {
          if path.hasSuffix(subfoldersToExclude) {
            return false
          }
        }

        return true
      }
  }

}

// MARK: - Error

enum Error: Swift.Error {
  case unknownError(exitCode: Int)
  case lintFailure
}
