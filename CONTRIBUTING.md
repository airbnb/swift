# Contributing

To contribute a new style rule first fork the repo and create your branch from `master`. Then open a PR and propose the rule following the structure below.

If you have an idea that's not completely fleshed out, please [open an issue](https://github.com/airbnb/swift/issues/new) to discuss.

## Structure of a new rule:

At minimum every rule should contain:

1. A permalink to reference easily.
1. A short description.
1. A link to the appropriate [SwiftLint](https://github.com/realm/SwiftLint) / [SwiftFormat](https://github.com/nicklockwood/SwiftFormat) rule.
1. _(optional)_ A "Why?" section describing the reasoning behind the rule.
1. A code example describing the incorrect and correct behaviours.

#### Example:

* <a id='an-id'></a><a href='#an-id'>(link)</a>
**This is the description of the rule.** [![SwiftLint: some_rule](https://img.shields.io/badge/SwiftLint-some__rule-008489.svg)](https://github.com/realm/SwiftLint/blob/master/Rules.md#some_rule) [![SwiftFormat: some_rule](https://img.shields.io/badge/SwiftFormat-some__rule-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat#rules)

  <details>

  #### Why?
  This is an explanation of why this rule is needed.

  ```swift
  // WRONG
  func someIncorrectCode {}

  // GOOD
  func someGoodCode {}
  ```

  </details>
