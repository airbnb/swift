import Foundation
import PackagePlugin
#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin
#endif

// MARK: - AirbnbSwiftFormatPlugin

/// A Swift Package Manager `CommandPlugin` and `XcodeCommandPlugin` that executes
/// `AirbnbSwiftFormatTool` to format source code in Swift package targets according
/// to the Airbnb Swift Style Guide.
@main
struct AirbnbSwiftFormatPlugin {

  /// Calls the `AirbnbSwiftFormatTool` executable with the given arguments
  func performCommand(
    context: CommandContext,
    inputPaths: [String],
    arguments: [String])
    throws
  {
    var argumentExtractor = ArgumentExtractor(arguments)

    // Filter out any excluded paths passed in with `--exclude`
    let excludedPaths = argumentExtractor.extractOption(named: "exclude")
    let inputPaths = inputPaths.filter { path in
      !excludedPaths.contains(where: { excludedPath in
        path.hasSuffix(excludedPath)
      })
    }

    let launchPath = try context.tool(named: "AirbnbSwiftFormatTool").path.string
    let arguments = inputPaths + [
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
    ] + argumentExtractor.remainingArguments

    if arguments.contains("--log") {
      // swiftlint:disable:next no_direct_standard_out_logs
      print("[Plugin]", launchPath, arguments.joined(separator: " "))
    }

    let process = Process()
    process.launchPath = launchPath
    process.arguments = arguments
    try process.run()
    process.waitUntilExit()

    switch process.terminationStatus {
    case EXIT_SUCCESS:
      break
    case EXIT_FAILURE:
      throw CommandError.lintFailure
    default:
      throw CommandError.unknownError(exitCode: process.terminationStatus)
    }
  }

}

// MARK: CommandPlugin

extension AirbnbSwiftFormatPlugin: CommandPlugin {

  // MARK: Internal

  func performCommand(context: PluginContext, arguments: [String]) async throws {
    var argumentExtractor = ArgumentExtractor(arguments)

    // When ran from Xcode, the plugin command is invoked with `--target` arguments,
    // specifying the targets selected in the plugin dialog.
    let inputTargets = argumentExtractor.extractOption(named: "target")

    // If given, lint only the paths passed to `--paths`
    var inputPaths = argumentExtractor.extractOption(named: "paths")

    if !inputTargets.isEmpty {
      // If a set of input targets were given, lint/format the directory for each of them
      inputPaths += try context.package.targets(named: inputTargets).map { $0.directory.string }
    } else if inputPaths.isEmpty {
      // Otherwise if no targets or paths listed we default to linting/formatting
      // the entire package directory.
      inputPaths = try self.inputPaths(for: context.package)
    }

    // When running on a SPM package we infer the minimum Swift version from the
    // `swift-tools-version` in `Package.swift` by default if the user doesn't
    // specify one manually
    let swiftVersion = argumentExtractor.extractOption(named: "swift-version").last
      ?? "\(context.package.toolsVersion.major).\(context.package.toolsVersion.minor)"

    let arguments = [
      "--swift-version",
      swiftVersion,
    ] + argumentExtractor.remainingArguments

    try performCommand(
      context: context,
      inputPaths: inputPaths,
      arguments: arguments)
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
  private func inputPaths(for package: Package) throws -> [String] {
    let packageDirectoryContents = try FileManager.default.contentsOfDirectory(
      at: URL(fileURLWithPath: package.directory.string),
      includingPropertiesForKeys: nil,
      options: [.skipsHiddenFiles])

    let subdirectories = packageDirectoryContents.filter { $0.hasDirectoryPath }
    let rootSwiftFiles = packageDirectoryContents.filter { $0.pathExtension.hasSuffix("swift") }
    return (subdirectories + rootSwiftFiles).map { $0.path }
  }

}

#if canImport(XcodeProjectPlugin)
extension AirbnbSwiftFormatPlugin: XcodeCommandPlugin {

  func performCommand(context: XcodePluginContext, arguments: [String]) throws {
    var argumentExtractor = ArgumentExtractor(arguments)

    // When ran from Xcode, the plugin command is invoked with `--target` arguments,
    // specifying the targets selected in the plugin dialog.
    //  - Unlike SPM targets which are just directories, Xcode targets are
    //    an arbitrary collection of paths.
    let inputTargetNames = Set(argumentExtractor.extractOption(named: "target"))
    let inputPaths = context.xcodeProject.targets.lazy
      .filter { inputTargetNames.contains($0.displayName) }
      .flatMap { $0.inputFiles }
      .map { $0.path.string }
      .filter { $0.hasSuffix(".swift") }

    try performCommand(
      context: context,
      inputPaths: Array(inputPaths),
      arguments: argumentExtractor.remainingArguments)
  }

}
#endif

// MARK: - CommandError

enum CommandError: Error {
  case lintFailure
  case unknownError(exitCode: Int32)
}
