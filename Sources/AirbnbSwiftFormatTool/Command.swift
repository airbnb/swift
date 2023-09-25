// Created by Cal Stephens on 9/25/23.
// Copyright © 2023 Airbnb Inc. All rights reserved.

import Foundation

/// A single command line invocation
struct Command {

  // MARK: Internal

  /// Mock implementation of `Command.run` which can be provided during unit test
  static var _mockRunCommand: ((Command) -> Int32)?

  let log: Bool
  let launchPath: String
  let arguments: [String]

  /// Synchronously runs this command and returns its exit code
  func run() throws -> Int32 {
    if let _mockRunCommand = Command._mockRunCommand {
      return _mockRunCommand(self)
    }

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

  // MARK: Private

  private func log(_ string: String) {
    // swiftlint:disable:next no_direct_standard_out_logs
    print("[AibnbSwiftFormatTool]", string)
  }

}
