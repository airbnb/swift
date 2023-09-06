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
      static func airbnbDefault() -> [SwiftSetting] {
        [
          .enableUpcomingFeature("BareSlashRegexLiterals"),
          .enableUpcomingFeature("ConciseMagicFile"),
          .enableUpcomingFeature("ImplicitOpenExistentials"),
        ]
      }
    }
    """
}

extension SwiftSettings {

  // MARK: Internal

  /// Finds all of the `Package.swift` package manifest files in the given package directory,
  /// and updates the `[SwiftSetting].airbnbDefault()` declaration if present.
  @available(macOS 13.0, *)
  static func updatePackageManifests(in packageDirectory: URL, lintOnly: Bool, verbose: Bool) throws {
    for packageManifestURL in packageManifestURLs(in: packageDirectory) {
      var contents = try String(contentsOf: packageManifestURL)
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

      guard contents != originalContent else {
        if verbose {
          log("Validated Swift Settings in \(packageManifestURL.lastPathComponent)")
        }

        continue
      }

      if lintOnly {
        log("[SwiftSetting].airbnbDefault() is out of date in \(packageManifestURL.lastPathComponent).")
        throw ExitCode.failure
      } else {
        try contents.write(to: packageManifestURL, atomically: true, encoding: .utf8)

        if verbose {
          log("Updated Swift Settings in \(packageManifestURL.lastPathComponent)")
        }
      }
    }
  }

  // MARK: Private

  private static func log(_ string: String) {
    // swiftlint:disable:next no_direct_standard_out_logs
    print("[AibnbSwiftFormatTool]", string)
  }

  private static func packageManifestURLs(in packageDirectory: URL) -> [URL] {
    let enumerator = FileManager.default.enumerator(
      at: packageDirectory,
      includingPropertiesForKeys: nil,
      options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles])

    var packageManifestURLs = [URL]()

    while let fileURL = enumerator?.nextObject() as? URL {
      let fileName = fileURL.lastPathComponent

      if
        fileName == "Package.swift"
        || (fileName.hasPrefix("Package@swift-") && fileName.hasSuffix(".swift"))
      {
        packageManifestURLs.append(fileURL)
      }
    }

    return packageManifestURLs
  }
}
