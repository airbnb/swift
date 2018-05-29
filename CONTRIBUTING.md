# Contributing

To contribute to this repository, please open a PR to propose a new style rule. Every new rule should be done through a PR.

If you have an idea that's not completely fleshed out, please open an issue to discuss.

After a PR is approved and merged please remember to send a PSA to ios@airbnb.com with the new merged approved style.

## Structure of a new rule:

At minimum every rule should contain:

1. A permalink to reference easily.
1. A short description.
1. If the rule is lintable, a link to the appropriate SwiftLint rule.
1. A code example describing the incorrect and correct behaviours.

#### Example:

* <a id='an-id'></a><a href='#an-id'>(link)</a>
**This is the description of the rule.** SwiftLint: [`some_rule`](https://github.com/realm/SwiftLint/blob/master/Rules.md#some-rule)

```swift
// WRONG
func someIncorrectCode {}

// GOOD
func someGoodCode {}
```
