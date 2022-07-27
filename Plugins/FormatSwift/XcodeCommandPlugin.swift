#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

struct AirbnbSwiftFormatXcodeCommandPlugin: XcodeCommandPlugin {
  
  func performCommand(context: XcodeProjectPlugin.XcodePluginContext, arguments: [String]) throws {
    print("Hello from Xcode")
  }
  
  
}
#endif
