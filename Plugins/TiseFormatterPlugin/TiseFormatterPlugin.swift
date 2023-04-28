import Foundation
import PackagePlugin

@main
public struct TiseFormatterPlugin: BuildToolPlugin {

    public init() {
        print("formatter init")
    }

    public func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        guard let sourceTarget = target as? SourceModuleTarget else {
            return []
        }
        return [
            lint(
                inputFiles: sourceTarget.sourceFiles(withSuffix: "swift").map(\.path),
                packageDirectory: context.package.directory,
                workingDirectory: context.pluginWorkDirectory,
                tool: try context.tool(named: "swiftlint")
            ),
            format(
                inputFiles: sourceTarget.sourceFiles(withSuffix: "swift").map(\.path),
                packageDirectory: context.package.directory,
                workingDirectory: context.pluginWorkDirectory,
                tool: try context.tool(named: "swiftformat")
            ),
        ].compactMap { $0 }
    }

    private func format(
        inputFiles: [Path],
        packageDirectory: Path,
        workingDirectory: Path,
        tool: PluginContext.Tool
    ) -> Command? {

        if inputFiles.isEmpty {
            // Don't lint anything if there are no Swift source files in this target
            return nil
        }

        var arguments: [String] = [
//            "lint",
//            "--quiet",
//            // We always pass all of the Swift source files in the target to the tool,
//            // so we need to ensure that any exclusion rules in the configuration are
//            // respected.
//            "--force-exclude",
//            "--cache-path", "\(workingDirectory)"
        ]

        // Manually look for configuration files, to avoid issues when the plugin does not execute our tool from the
        // package source directory.

        arguments.append(contentsOf: ["--config", "\(packageDirectory.string + "/FormatRules/tise.swiftformat")"])
        arguments += inputFiles.map(\.string)

        // We are not producing output files and this is needed only to not include cache files into bundle
        let outputFilesDirectory = workingDirectory.appending("Output")

        return
            .prebuildCommand(
                displayName: "SwiftFormat",
                executable: tool.path,
                arguments: arguments,
                outputFilesDirectory: outputFilesDirectory
            )
    }



    private func lint(
        inputFiles: [Path],
        packageDirectory: Path,
        workingDirectory: Path,
        tool: PluginContext.Tool
    ) -> Command? {

        if inputFiles.isEmpty {
            // Don't lint anything if there are no Swift source files in this target
            return nil
        }

        var arguments = [
            "lint",
            "--quiet",
            // We always pass all of the Swift source files in the target to the tool,
            // so we need to ensure that any exclusion rules in the configuration are
            // respected.
            "--force-exclude",
            "--cache-path", "\(workingDirectory)"
        ]

        // Manually look for configuration files, to avoid issues when the plugin does not execute our tool from the
        // package source directory.

        arguments.append(contentsOf: ["--config", "\(packageDirectory.string + "/FormatRules/swiftlint.yml")"])
        arguments += inputFiles.map(\.string)

        // We are not producing output files and this is needed only to not include cache files into bundle
        let outputFilesDirectory = workingDirectory.appending("Output")

        print("Tool", tool)

        return
            .prebuildCommand(
                displayName: "SwiftLint",
                executable: tool.path,
                arguments: arguments,
                outputFilesDirectory: outputFilesDirectory
            )
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension TiseFormatterPlugin: XcodeBuildToolPlugin {
    public func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
        print("XcodeProjectPlugin init")
        print("🥊", context)

        let inputFilePaths = target.inputFiles
            .filter { $0.type == .source && $0.path.extension == "swift" }
            .map(\.path)

        print("🥊", target)

        return [
            lint(
                inputFiles: inputFilePaths,
                packageDirectory: context.xcodeProject.directory,
                workingDirectory: context.pluginWorkDirectory,
                tool: try context.tool(named: "swiftlint")
            ),
            format(
                inputFiles: inputFilePaths,
                packageDirectory: context.xcodeProject.directory,
                workingDirectory: context.pluginWorkDirectory,
                tool: try context.tool(named: "swiftformat")
            )
        ].compactMap { $0 }
    }
}
#endif


import Foundation
import PackagePlugin

extension Path {
    /// Scans the receiver, then all of its parents looking for a configuration file with the name ".swiftlint.yml".
    ///
    /// - returns: Path to the configuration file, or nil if one cannot be found.
    func firstConfigurationFileInParentDirectories() -> Path? {
        let defaultConfigurationFileName = ".swiftlint.yml"
        let proposedDirectory = sequence(
            first: self,
            next: { path in
                guard path.stem.count > 1 else {
                    // Check we're not at the root of this filesystem, as `removingLastComponent()`
                    // will continually return the root from itself.
                    return nil
                }

                return path.removingLastComponent()
            }
        ).first { path in
            let potentialConfigurationFile = path.appending(subpath: defaultConfigurationFileName)
            return potentialConfigurationFile.isAccessible()
        }
        return proposedDirectory?.appending(subpath: defaultConfigurationFileName)
    }

    /// Safe way to check if the file is accessible from within the current process sandbox.
    private func isAccessible() -> Bool {
        let result = string.withCString { pointer in
            access(pointer, R_OK)
        }

        return result == 0
    }
}
