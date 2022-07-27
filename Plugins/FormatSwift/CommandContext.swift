import PackagePlugin

// MARK: - CommandContext

/// Shared methods implemented by `PluginContext` and
protocol CommandContext {
  var pluginWorkDirectory: Path { get }
  func tool(named name: String) throws -> PluginContext.Tool
}

// MARK: - PluginContext + CommandContext

extension PluginContext: CommandContext { }

#if canImport(XcodeProjectPlugin)

#endif
