# Airbnb Swift Style Guide

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fairbnb%2Fswift%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/airbnb/swift)

## Swift Package Manager command plugin

This repo includes a Swift Package Manager command plugin that you can use to automatically reformat or lint your package according to the style guide. To use this command plugin with your package, all you need to do is add this repo as a dependency:

```swift
dependencies: [
  .package(url: "https://github.com/airbnb/swift", from: "1.0.0"),
]
```

and then run the `format` command plugin in your package directory:

```shell
$ swift package format
```

<details>
<summary>Usage guide</summary>

```shell
# Supported in Xcode 14+. Prompts for permission to write to the package directory.
$ swift package format

# When using the Xcode 13 toolchain, or a noninteractive shell, you must use:
$ swift package --allow-writing-to-package-directory format

# To just lint without reformatting, you can use `--lint`:
$ swift package format --lint

# By default the command plugin runs on the entire package directory.
# You can exclude directories using `exclude`:
$ swift package format --exclude Tests

# Alternatively you can explicitly list the set of paths and/or SPM targets:
$ swift package format --paths Sources Tests Package.swift
$ swift package format --targets AirbnbSwiftFormatTool

# The plugin infers your package's minimum Swift version from the `swift-tools-version`
# in your `Package.swift`, but you can provide a custom value with `--swift-version`:
$ swift package format --swift-version 5.3
```

The package plugin returns a non-zero exit code if there is a lint failure that requires attention.
 - In `--lint` mode, any lint failure from any tool will result in a non-zero exit code.
 - In standard autocorrect mode without `--lint`, only failures from SwiftLint lint-only rules will result in a non-zero exit code.

</details>
