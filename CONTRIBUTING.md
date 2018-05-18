# Contributing

To contribute to this repository, please open a PR to propose a new style rule. Every new rule should be done through a PR.

If you have an idea that's not completely fleshed out, please open an issue to discuss.

After a PR is approved and merged please remember to send a PSA to ios@airbnb.com with the new merged approved style.

## Structure of a new rule:

Every rule should contain:

1. A link to reference easily.
1. A short description.
1. A link to the appropiate SwiftLint rule.
1. A code example describing the incorrect and correct behaviours.

#### Example:

* <a id='an-id'></a> <a href='#an-id'>(link)</a>
**This is the description of the rule.** swiftlint: <a href='https://github.com/realm/SwiftLint/blob/master/Rules.md#some-rule'>some-rule</a>

```swift
// WRONG
func someIncorrectCode {}

// GOOD
func someGoodCode {}
```

## Things that will not be considered:
- A change that goes against the [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/).
- A change that goes against Xcode's <kbd>^</kbd> + <kbd>I</kbd> indentation behavior.
