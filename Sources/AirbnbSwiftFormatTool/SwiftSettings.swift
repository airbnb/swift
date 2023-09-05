// Created by Cal Stephens on 9/5/23.
// Copyright © 2023 Airbnb Inc. All rights reserved.

import ArgumentParser
import Foundation
import RegexBuilder

// MARK: - SwiftSettings

enum SwiftSettings {
  /// Default Swift compiler flags recommended by the Airbnb Swift Style Guide.
  ///
  /// If targeting `swift-tools-version: 5.8` or later, you can include this
  /// extension in your `Package.swift` and use it in your targets like
  /// `swiftSettings: .airbnbDefault()`.
  ///
  /// This tool will also keep the `airbnbDefault` settings in your Package.swift
  /// up to date automatically, if it detects an `extension [SwiftSetting]` with
  /// the `airbnbDefault` settings already defined.
  static let airbnbDefaultSwiftSettings = """
    extension [SwiftSetting] {
      /// Default Swift compiler flags recommended by the Airbnb Swift Style Guide.
      /// Do not modify: updated automatically by Airbnb Swift Format Tool.
      ///
      /// - Parameter foundationModule: Whether or not this target is considered
      ///   a "foundation module". We currently only recommend using strict
      ///   concurrency checking in foundational modules, rather than feature modules.
      static func airbnbDefault(foundationModule: Bool = false) -> [SwiftSetting] {
        var settings = [SwiftSetting]()
        settings.append(.enableExperimentalFeature("BareSlashRegexLiterals"))
        settings.append(.enableExperimentalFeature("ConciseMagicFile"))
        settings.append(.enableExperimentalFeature("ImplicitOpenExistentials"))

        if foundationModule {
          settings.append(.enableUpcomingFeature("StrictConcurrency"))
        }

        return settings
      }
    }
    """
}

extension SwiftSettings {

  // MARK: Internal

  @available(macOS 13.0, *)
  static func updatePackageManifest(at packageManifestPath: String, lintOnly: Bool) throws {
    var contents = try String(contentsOfFile: packageManifestPath)
    let originalContent = contents

    let extensionRegex = Regex {
      "extension [SwiftSetting] {"
      OneOrMore { .any }
      "static func airbnbDefault"
      OneOrMore { .any }
      OneOrMore { .newlineSequence }
      "}"
    }

    contents.replace(extensionRegex, with: airbnbDefaultSwiftSettings)

    guard contents != originalContent else { return }

    if lintOnly {
      log("Package.swift `[SwiftSetting].airbnbDefault()` is out of date.")
      throw ExitCode.failure
    } else {
      try contents.write(toFile: packageManifestPath, atomically: true, encoding: .utf8)
    }
  }

  // MARK: Private

  private static func log(_ string: String) {
    // swiftlint:disable:next no_direct_standard_out_logs
    print("[AibnbSwiftFormatTool]", string)
  }
}
