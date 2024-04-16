import Foundation

// MARK: - Command

/// A single command line invocation
struct Command {
    /// This property can be overridden to provide a mock implementation in unit tests.
    static var runCommand: (Self) throws -> Int32 = { try $0.executeShellCommand() }
    
    let log: Bool
    let launchPath: String
    let arguments: [String]
    
    /// Runs this command using the implementation of `Command.runCommand`
    ///  - By default, synchronously runs this command and returns its exit code
    func run() throws -> Int32 {
        try Self.runCommand(self)
    }
}

// MARK: - Private

extension Command {
    /// Synchronously runs this command and returns its exit code
    private func executeShellCommand() throws -> Int32 {
        let process = Process()
        process.launchPath = launchPath
        process.arguments = arguments
        
        if log {
            log(process.shellCommand)
        }
        
        try process.run()
        process.waitUntilExit()
        
        if log {
            let commandName = process.launchPath?.components(separatedBy: "/").last ?? "unknown"
            log("\(commandName) command completed with exit code \(process.terminationStatus)")
        }
        
        return process.terminationStatus
    }
    
    private func log(_ string: String) {
        // swiftlint:disable:next no_direct_standard_out_logs
        print("[AibnbSwiftFormatTool]", string)
    }
}
