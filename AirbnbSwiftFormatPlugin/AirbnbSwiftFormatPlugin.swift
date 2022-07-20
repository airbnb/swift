import Foundation
import PackagePlugin

/// A Swift Package Manager `CommandPlugin` that executes `AirbnbSwiftFormatTool`
/// to format source code in Swift package targets according to the Airbnb Swift Style Guide.
@main
struct AirbnbSwiftFormatPlugin: CommandPlugin {

  func performCommand(context: PluginContext, arguments: [String]) async throws {
    let process = Process()
    process.launchPath = try context.tool(named: "AirbnbSwiftFormatTool").path.string

    var processArguments = try inputPaths(context: context) + [
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
  private func inputPaths(context: PluginContext) throws -> [String] {
    let packageDirectoryContents = try FileManager.default.contentsOfDirectory(
      at: URL(fileURLWithPath: context.package.directory.string),
      includingPropertiesForKeys: nil,
      options: [.skipsHiddenFiles])

    let subdirectories = packageDirectoryContents.filter { $0.hasDirectoryPath }
    let rootSwiftFiles = packageDirectoryContents.filter { $0.pathExtension.hasSuffix("swift") }
    return (subdirectories + rootSwiftFiles).map { $0.path }
  }

}

enum LintError: Error {
  case lintFailure
}
