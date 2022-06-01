# Airbnb Swift Style Guide

## Goals

Following this style guide should:

* Make it easier to read and begin understanding unfamiliar code.
* Make code easier to maintain.
* Reduce simple programmer errors.
* Reduce cognitive load while coding.
* Keep discussions on diffs focused on the code's logic rather than its style.

Note that brevity is not a primary goal. Code should be made more concise only if other good code qualities (such as readability, simplicity, and clarity) remain equal or are improved.

## Guiding Tenets

* This guide is in addition to the official [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/). These rules should not contradict that document.
* These rules should not fight Xcode's <kbd>^</kbd> + <kbd>I</kbd> indentation behavior.
* We strive to make every rule lintable:
  * If a rule changes the format of the code, it needs to be able to be reformatted automatically (either using [SwiftLint](https://github.com/realm/SwiftLint) autocorrect or [SwiftFormat](https://github.com/nicklockwood/SwiftFormat)).
  * For rules that don't directly change the format of the code, we should have a lint rule that throws a warning.
  * Exceptions to these rules should be rare and heavily justified.

## Table of Contents

1. [Xcode Formatting](#xcode-formatting)
1. [Naming](#naming)
1. [Style](#style)
    1. [Functions](#functions)
    1. [Closures](#closures)
    1. [Operators](#operators)
1. [Patterns](#patterns)
1. [File Organization](#file-organization)
1. [Objective-C Interoperability](#objective-c-interoperability)
1. [Contributors](#contributors)
1. [Amendments](#amendments)

## Xcode Formatting

_You can enable the following settings in Xcode by running [this script](resources/xcode_settings.bash), e.g. as part of a "Run Script" build phase._

* <a id='column-width'></a>(<a href='#column-width'>link</a>) **Each line should have a maximum column width of 100 characters.** [![SwiftFormat: wrap](https://img.shields.io/badge/SwiftFormat-wrap-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/master/Rules.md#wrap)

  <details>

  #### Why?
  Due to larger screen sizes, we have opted to choose a page guide greater than 80. 
  
  We currently only "strictly enforce" (lint / auto-format) a maximum column width of 130 characters to limit the cases where manual clean up is required for reformatted lines that fall slightly above the threshold.

  </details>

* <a id='spaces-over-tabs'></a>(<a href='#spaces-over-tabs'>link</a>) **Use 2 spaces to indent lines.** [![SwiftFormat: indent](https://img.shields.io/badge/SwiftFormat-indent-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/master/Rules.md#indent)

* <a id='trailing-whitespace'></a>(<a href='#trailing-whitespace'>link</a>) **Trim trailing whitespace in all lines.** [![SwiftFormat: trailingSpace](https://img.shields.io/badge/SwiftFormat-trailingSpace-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/master/Rules.md#trailingSpace)

**[⬆ back to top](#table-of-contents)**

## Naming

* <a id='use-camel-case'></a>(<a href='#use-camel-case'>link</a>) **Use PascalCase for type and protocol names, and lowerCamelCase for everything else.**

  <details>

  ```swift
  protocol SpaceThing {
    // ...
  }

  class SpaceFleet: SpaceThing {

    enum Formation {
      // ...
    }

    class Spaceship {
      // ...
    }

    var ships: [Spaceship] = []
    static let worldName: String = "Earth"

    func addShip(_ ship: Spaceship) {
      // ...
    }
  }

  let myFleet = SpaceFleet()
  ```

  </details>

  _Exception: You may prefix a private property with an underscore if it is backing an identically-named property or method with a higher access level_

  <details>

  #### Why?
  There are specific scenarios where a backing a property or method could be easier to read than using a more descriptive name.

  - Type erasure

  ```swift
  public final class AnyRequester<ModelType>: Requester {

    public init<T: Requester>(_ requester: T) where T.ModelType == ModelType {
      _executeRequest = requester.executeRequest
    }

    @discardableResult
    public func executeRequest(
      _ request: URLRequest,
      onSuccess: @escaping (ModelType, Bool) -> Void,
      onFailure: @escaping (Error) -> Void)
      -> URLSessionCancellable
    {
      return _executeRequest(request, session, parser, onSuccess, onFailure)
    }

    private let _executeRequest: (
      URLRequest,
      @escaping (ModelType, Bool) -> Void,
      @escaping (NSError) -> Void)
      -> URLSessionCancellable

  }
  ```

  - Backing a less specific type with a more specific type

  ```swift
  final class ExperiencesViewController: UIViewController {
    // We can't name this view since UIViewController has a view: UIView property.
    private lazy var _view = CustomView()

    loadView() {
      self.view = _view
    }
  }
  ```

  </details>

* <a id='bool-names'></a>(<a href='#bool-names'>link</a>) **Name booleans like `isSpaceship`, `hasSpacesuit`, etc.** This makes it clear that they are booleans and not other types.

* <a id='capitalize-acronyms'></a>(<a href='#capitalize-acronyms'>link</a>) **Acronyms in names (e.g. `URL`) should be all-caps except when it’s the start of a name that would otherwise be lowerCamelCase, in which case it should be uniformly lower-cased.**

  <details>

  ```swift
  // WRONG
  class UrlValidator {

    func isValidUrl(_ URL: URL) -> Bool {
      // ...
    }

    func isProfileUrl(_ URL: URL, for userId: String) -> Bool {
      // ...
    }
  }

  let URLValidator = UrlValidator()
  let isProfile = URLValidator.isProfileUrl(URLToTest, userId: IDOfUser)

  // RIGHT
  class URLValidator {

    func isValidURL(_ url: URL) -> Bool {
      // ...
    }

    func isProfileURL(_ url: URL, for userID: String) -> Bool {
      // ...
    }
  }

  let urlValidator = URLValidator()
  let isProfile = urlValidator.isProfileURL(urlToTest, userID: idOfUser)
  ```

  </details>

* <a id='general-part-first'></a>(<a href='#general-part-first'>link</a>) **Names should be written with their most general part first and their most specific part last.** The meaning of "most general" depends on context, but should roughly mean "that which most helps you narrow down your search for the item you're looking for." Most importantly, be consistent with how you order the parts of your name.

  <details>

  ```swift
  // WRONG
  let rightTitleMargin: CGFloat
  let leftTitleMargin: CGFloat
  let bodyRightMargin: CGFloat
  let bodyLeftMargin: CGFloat

  // RIGHT
  let titleMarginRight: CGFloat
  let titleMarginLeft: CGFloat
  let bodyMarginRight: CGFloat
  let bodyMarginLeft: CGFloat
  ```

  </details>

* <a id='hint-at-types'></a>(<a href='#hint-at-types'>link</a>) **Include a hint about type in a name if it would otherwise be ambiguous.**

  <details>

  ```swift
  // WRONG
  let title: String
  let cancel: UIButton

  // RIGHT
  let titleText: String
  let cancelButton: UIButton
  ```

  </details>

* <a id='past-tense-events'></a>(<a href='#past-tense-events'>link</a>) **Event-handling functions should be named like past-tense sentences.** The subject can be omitted if it's not needed for clarity.

  <details>

  ```swift
  // WRONG
  class ExperiencesViewController {

    private func handleBookButtonTap() {
      // ...
    }

    private func modelChanged() {
      // ...
    }
  }

  // RIGHT
  class ExperiencesViewController {

    private func didTapBookButton() {
      // ...
    }

    private func modelDidChange() {
      // ...
    }
  }
  ```

  </details>

* <a id='avoid-class-prefixes'></a>(<a href='#avoid-class-prefixes'>link</a>) **Avoid Objective-C-style acronym prefixes.** This is no longer needed to avoid naming conflicts in Swift.

  <details>

  ```swift
  // WRONG
  class AIRAccount {
    // ...
  }

  // RIGHT
  class Account {
    // ...
  }
  ```

  </details>

* <a id='avoid-controller-suffix'></a>(<a href='#avoid-controller-suffix'>link</a>) **Avoid `*Controller` in names of classes that aren't view controllers.**
  <details>

  #### Why?
  Controller is an overloaded suffix that doesn't provide information about the responsibilities of the class.

  </details>

**[⬆ back to top](#table-of-contents)**

## Style

* <a id='use-implicit-types'></a>(<a href='#use-implicit-types'>link</a>) **Don't include types where they can be easily inferred.** [![SwiftFormat: redundantType](https://img.shields.io/badge/SwiftFormat-redundantType-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/master/Rules.md#redundantType)

  <details>

  ```swift
  // WRONG
  let host: Host = Host()

  // RIGHT
  let host = Host()
  ```

  ```swift
  enum Direction {
    case left
    case right
  }

  func someDirection() -> Direction {
    // WRONG
    return Direction.left

    // RIGHT
    return .left
  }
  ```

  </details>

* <a id='omit-self'></a>(<a href='#omit-self'>link</a>) **Don't use `self` unless it's necessary for disambiguation or required by the language.** [![SwiftFormat: redundantSelf](https://img.shields.io/badge/SwiftFormat-redundantSelf-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/master/Rules.md#redundantSelf)

  <details>

  ```swift
  final class Listing {

    init(capacity: Int, allowsPets: Bool) {
      // WRONG
      self.capacity = capacity
      self.isFamilyFriendly = !allowsPets // `self.` not required here

      // RIGHT
      self.capacity = capacity
      isFamilyFriendly = !allowsPets
    }

    private let isFamilyFriendly: Bool
    private var capacity: Int

    private func increaseCapacity(by amount: Int) {
      // WRONG
      self.capacity += amount

      // RIGHT
      capacity += amount

      // WRONG
      self.save()

      // RIGHT
      save()
    }
  }
  ```

  </details>

* <a id='upgrade-self'></a>(<a href='#upgrade-self'>link</a>) **Bind to `self` when upgrading from a weak reference.** [![SwiftFormat: strongifiedSelf](https://img.shields.io/badge/SwiftFormat-strongifiedSelf-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/master/Rules.md#strongifiedSelf)

  <details>

  ```swift
  //WRONG
  class MyClass {

    func request(completion: () -> Void) {
      API.request() { [weak self] response in
        guard let strongSelf = self else { return }
        // Do work
        completion()
      }
    }
  }

  // RIGHT
  class MyClass {

    func request(completion: () -> Void) {
      API.request() { [weak self] response in
        guard let self = self else { return }
        // Do work
        completion()
      }
    }
  }
  ```

  </details>

* <a id='trailing-comma-array'></a>(<a href='#trailing-comma-array'>link</a>) **Add a trailing comma on the last element of a multi-line array.** [![SwiftFormat: trailingCommas](https://img.shields.io/badge/SwiftFormat-trailingCommas-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/master/Rules.md#trailingCommas)

  <details>

  ```swift
  // WRONG
  let rowContent = [
    listingUrgencyDatesRowContent(),
    listingUrgencyBookedRowContent(),
    listingUrgencyBookedShortRowContent()
  ]

  // RIGHT
  let rowContent = [
    listingUrgencyDatesRowContent(),
    listingUrgencyBookedRowContent(),
    listingUrgencyBookedShortRowContent(),
  ]
  ```

* <a id='no-space-inside-collection-brackets'></a>(<a href='#no-space-inside-brackets'>link</a>) **There should be no spaces inside the brackets of collection literals.** [![SwiftFormat: spaceInsideBrackets](https://img.shields.io/badge/SwiftFormat-spaceInsideBrackets-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/master/Rules.md#spaceInsideBrackets)

  <details>

  ```swift
  // WRONG
  let innerPlanets = [ mercury, venus, earth, mars ]
  let largestObjects = [ .star: sun, .planet: jupiter  ]

  // RIGHT
  let innerPlanets = [mercury, venus, earth, mars]
  let largestObjects = [.star: sun, .planet: jupiter]
  ```

  </details>

* <a id='name-tuple-elements'></a>(<a href='#name-tuple-elements'>link</a>) **Name members of tuples for extra clarity.** Rule of thumb: if you've got more than 3 fields, you should probably be using a struct.

  <details>

  ```swift
  // WRONG
  func whatever() -> (Int, Int) {
    return (4, 4)
  }
  let thing = whatever()
  print(thing.0)

  // RIGHT
  func whatever() -> (x: Int, y: Int) {
    return (x: 4, y: 4)
  }

  // THIS IS ALSO OKAY
  func whatever2() -> (x: Int, y: Int) {
    let x = 4
    let y = 4
    return (x, y)
  }

  let coord = whatever()
  coord.x
  coord.y
  ```

  </details>

* <a id='colon-spacing'></a>(<a href='#colon-spacing'>link</a>) **Place the colon immediately after an identifier, followed by a space.** [![SwiftLint: colon](https://img.shields.io/badge/SwiftLint-colon-007A87.svg)](https://realm.github.io/SwiftLint/colon)

  <details>

  ```swift
  // WRONG
  var something : Double = 0

  // RIGHT
  var something: Double = 0
  ```

  ```swift
  // WRONG
  class MyClass : SuperClass {
    // ...
  }

  // RIGHT
  class MyClass: SuperClass {
    // ...
  }
  ```

  ```swift
  // WRONG
  var dict = [KeyType:ValueType]()
  var dict = [KeyType : ValueType]()

  // RIGHT
  var dict = [KeyType: ValueType]()
  ```

  </details>

* <a id='return-arrow-spacing'></a>(<a href='#return-arrow-spacing'>link</a>) **Place a space on either side of a return arrow for readability.** [![SwiftLint: return_arrow_whitespace](https://img.shields.io/badge/SwiftLint-return__arrow__whitespace-007A87.svg)](https://realm.github.io/SwiftLint/return_arrow_whitespace)

  <details>

  ```swift
  // WRONG
  func doSomething()->String {
    // ...
  }

  // RIGHT
  func doSomething() -> String {
    // ...
  }
  ```

  ```swift
  // WRONG
  func doSomething(completion: ()->Void) {
    // ...
  }

  // RIGHT
  func doSomething(completion: () -> Void) {
    // ...
  }
  ```

  </details>

* <a id='unnecessary-parens'></a>(<a href='#unnecessary-parens'>link</a>) **Omit unnecessary parentheses.** [![SwiftFormat: redundantParens](https://img.shields.io/badge/SwiftFormat-redundantParens-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/master/Rules.md#redundantParens)

  <details>

  ```swift
  // WRONG
  if (userCount > 0) { ... }
  switch (someValue) { ... }
  let evens = userCounts.filter { (number) in number.isMultiple(of: 2) }
  let squares = userCounts.map() { $0 * $0 }

  // RIGHT
  if userCount > 0 { ... }
  switch someValue { ... }
  let evens = userCounts.filter { number in number.isMultiple(of: 2) }
  let squares = userCounts.map { $0 * $0 }
  ```

  </details>

* <a id='unnecessary-enum-arguments'></a> (<a href='#unnecessary-enum-arguments'>link</a>) **Omit enum associated values from case statements when all arguments are unlabeled.** [![SwiftFormat: redundantPattern](https://img.shields.io/badge/SwiftFormat-redundantPattern-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/master/Rules.md#redundantPattern)

  <details>

  ```swift
  // WRONG
  if case .done(_) = result { ... }

  switch animal {
  case .dog(_, _, _):
    ...
  }

  // RIGHT
  if case .done = result { ... }

  switch animal {
  case .dog:
    ...
  }
  ```

  </details>

* <a id='inline-let-when-destructuring'></a> (<a href='#inline-let-when-destructuring'>link</a>) **When destructuring an enum case or a tuple, place the `let` keyword inline, adjacent to each individual property assignment.** [![SwiftFormat: hoistPatternLet](https://img.shields.io/badge/SwiftFormat-hoistPatternLet-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/master/Rules.md#hoistPatternLet)

  <details>

    ```swift
    // WRONG
    switch result {
    case let .success(value):
      // ...
    case let .error(errorCode, errorReason):
      // ...
    }

    // WRONG
    guard let case .success(value) else {
      return
    }

    // RIGHT
    switch result {
    case .success(let value):
      // ...
    case .error(let errorCode, let errorReason):
      // ...
    }

    // RIGHT
    guard case .success(let value) else {
      return
    }
    ```

    #### Why?

    1. **Consistency**: We should prefer to either _always_ inline the `let` keyworkd or _never_ inline the `let` keyword. In Airbnb's Swift codebase, we [observed](https://github.com/airbnb/swift/pull/126#discussion_r631979244) that inline `let` is used far more often in practice (especially when destructuring enum cases with a single associated value).

    2. **Clarity**: Inlining the `let` keyword makes it more clear which identifiers are part of the conditional check and which identifiers are binding new variables, since the `let` keyword is always adjacent to the variable identifier.

    ```swift
    // `let` is adjacent to the variable identifier, so it is immediately obvious
    // at a glance that these identifiers represent new variable bindings
    case .enumCaseWithSingleAssociatedValue(let string):
    case .enumCaseWithMultipleAssociatedValues(let string, let int):

    // The `let` keyword is quite far from the variable identifiers,
    // so its less obvious that they represent new variable bindings
    case let .enumCaseWithSingleAssociatedValue(string):
    case let .enumCaseWithMultipleAssociatedValues(string, int):

    ```

  </details>

* <a id='attributes-on-prev-line'></a>(<a href='#attributes-on-prev-line'>link</a>) **Place function/type attributes on the line above the declaration**. [![SwiftFormat: wrapAttributes](https://img.shields.io/badge/SwiftFormat-wrapAttributes-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/master/Rules.md#wrapAttributes)

  <details>

  ```swift
  // WRONG
  @objc class Spaceship {

    @discardableResult func fly() -> Bool {
    }
  }

  // RIGHT

  @objc
  class Spaceship {

    @discardableResult
    func fly() -> Bool {
    }
  }
  ```

  </details>

* <a id='multi-line-array'></a>(<a href='#multi-line-array'>link</a>) **Multi-line arrays should have each bracket on a separate line.** Put the opening and closing brackets on separate lines from any of the elements of the array. Also add a trailing comma on the last element. [![SwiftFormat: wrapArguments](https://img.shields.io/badge/SwiftFormat-wrapArguments-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/master/Rules.md#wrapArguments)

  <details>

  ```swift
  // WRONG
  let rowContent = [listingUrgencyDatesRowContent(),
                    listingUrgencyBookedRowContent(),
                    listingUrgencyBookedShortRowContent()]

  let rowContent = [
    listingUrgencyDatesRowContent(),
    listingUrgencyBookedRowContent(),
    listingUrgencyBookedShortRowContent()
  ]

  // RIGHT
  let rowContent = [
    listingUrgencyDatesRowContent(),
    listingUrgencyBookedRowContent(),
    listingUrgencyBookedShortRowContent(),
  ]
  ```

* <a id='long-typealias'></a>(<a href='#long-typealias'>link</a>) [Long](https://github.com/airbnb/swift#column-width) typealiases of protocol compositions should wrap before the `=` and before each individual `&`. [![SwiftFormat: wrapArguments](https://img.shields.io/badge/SwiftFormat-wrapArguments-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/master/Rules.md#wrapArguments)

  <details>

  ```swift
  // WRONG (too long)
  public typealias Dependencies = UniverseBuilderProviding & LawsOfPhysicsProviding & UniverseSimulatorServiceProviding & PlanetBuilderProviding & CivilizationServiceProviding

  // WRONG (naive wrapping)
  public typealias Dependencies = UniverseBuilderProviding & LawsOfPhysicsProviding & UniverseSimulatorServiceProviding &
    PlanetBuilderProviding & CivilizationServiceProviding

  // WRONG (unbalanced)
  public typealias Dependencies = UniverseBuilderProviding
    & LawsOfPhysicsProviding
    & UniverseSimulatorServiceProviding
    & PlanetBuilderProviding
    & CivilizationServiceProviding

  // RIGHT
  public typealias Dependencies
    = UniverseBuilderProviding
    & LawsOfPhysicsProviding
    & UniverseSimulatorServiceProviding
    & PlanetBuilderProviding
    & CivilizationServiceProviding
  ```

* <a id='multi-line-conditions'></a>(<a href='#multi-line-conditions'>link</a>) **Multi-line conditional statements should break after the leading keyword.** Indent each individual statement by [2 spaces](https://github.com/airbnb/swift#spaces-over-tabs). [![SwiftFormat: wrapArguments](https://img.shields.io/badge/SwiftFormat-wrapArguments-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/master/Rules.md#wrapArguments)

  <details>

  #### Why?
  Breaking after the leading keyword resets indentation to the standard [2-space grid](https://github.com/airbnb/swift#spaces-over-tabs),
  which helps avoid fighting Xcode's <kbd>^</kbd> + <kbd>I</kbd> indentation behavior.

  ```swift
  // WRONG
  if let galaxy = galaxy,
    galaxy.name == "Milky Way" // Indenting by two spaces fights Xcode's ^+I indentation behavior
  { … }

  // WRONG
  guard let galaxy = galaxy,
        galaxy.name == "Milky Way" // Variable width indentation (6 spaces)
  else { … }

  // WRONG
  guard let earth = unvierse.find(
    .planet,
    named: "Earth"),
    earth.isHabitable // Blends in with previous condition's method arguments
  else { … }

  // RIGHT
  if
    let galaxy = galaxy,
    galaxy.name == "Milky Way"
  { … }

  // RIGHT
  guard
    let galaxy = galaxy,
    galaxy.name == "Milky Way"
  else { … }

  // RIGHT
  guard
    let earth = unvierse.find(
      .planet,
      named: "Earth"),
    earth.isHabitable
  else { … }

  // RIGHT
  if let galaxy = galaxy {
    …
  }

  // RIGHT
  guard let galaxy = galaxy else {
    …
  }
  ```

* <a id='indent-multiline-string-literals'></a>(<a href='#indent-multiline-string-literals'>link</a>) **Indent the body and closing triple-quote of multiline string literals**, unless the string literal begins on its own line in which case the string literal contents and closing triple-quote should have the same indentation as the opening triple-quote. [![SwiftFormat: indent](https://img.shields.io/badge/SwiftFormat-indent-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/master/Rules.md#indent)

  <details>

  ```swift
  // WRONG
  var spaceQuote = """
  “Space,” it says, “is big. Really big. You just won’t believe how vastly, hugely, mindbogglingly big it is.
  I mean, you may think it’s a long way down the road to the chemist’s, but that’s just peanuts to space.”
  """

  // RIGHT
  var spaceQuote = """
    “Space,” it says, “is big. Really big. You just won’t believe how vastly, hugely, mindbogglingly big it is.
    I mean, you may think it’s a long way down the road to the chemist’s, but that’s just peanuts to space.”
    """

  // WRONG
  var universeQuote: String {
    """
      In the beginning the Universe was created.
      This has made a lot of people very angry and been widely regarded as a bad move.
      """
  }

  // RIGHT
  var universeQuote: String {
    """
    In the beginning the Universe was created.
    This has made a lot of people very angry and been widely regarded as a bad move.
    """
  }
  ```

  </details>

* <a id='favor-constructors'></a>(<a href='#favor-constructors'>link</a>) **Use constructors instead of Make() functions for NSRange and others.** [![SwiftLint: legacy_constructor](https://img.shields.io/badge/SwiftLint-legacy__constructor-007A87.svg)](https://realm.github.io/SwiftLint/legacy_constructor)

  <details>

  ```swift
  // WRONG
  let range = NSMakeRange(10, 5)

  // RIGHT
  let range = NSRange(location: 10, length: 5)
  ```

  </details>

* <a id='standard-library-type-shorthand'></a>(<a href='#standard-library-type-sugar'>link</a>) **For standard library types with a canonical shorthand form (`Optional`, `Array`, `Dictionary`), prefer using the shorthand form over the full generic form.** [![SwiftFormat: typeSugar](https://img.shields.io/badge/SwiftFormat-typeSugar-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/master/Rules.md#typeSugar)

  <details>

  ```swift
  // WRONG
  let optional: Optional<String> = nil
  let array: Array<String> = []
  let dictionary: Dictionary<String, Any> = [:]

  // RIGHT
  let optional: String? = nil
  let array: [String] = []
  let dictionary: [String: Any] = [:]
  ```

  </details>

* <a id='omit-explicit-init'></a>(<a href='#omit-explicit-init'>link</a>) **Omit explicit `.init` when not reqired.** [![SwiftFormat: redundantInit](https://img.shields.io/badge/SwiftFormat-redundantInit-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/master/Rules.md#redundantInit)

  <details>

  ```swift
  // WRONG
  let universe = Universe.init()

  // RIGHT
  let universe = Universe()
  ```

  </details>

* <a id='single-line-expression-braces'></a>(<a href='#single-line-expression-braces'>link</a>) The opening brace following a single-line expression should be on the same line as the rest of the statement. [![SwiftFormat: braces](https://img.shields.io/badge/SwiftFormat-braces-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/master/Rules.md#braces)

  <details>

  ```swift
  // WRONG
  if !planet.isHabitable
  {
    planet.terraform()
  }

  class Planet
  {
    func terraform()
    {
      generateAtmosphere()
      generateOceans()
    }
  }

  // RIGHT
  if !planet.isHabitable {
    planet.terraform()
  }

  class Planet {
    func terraform() {
      generateAtmosphere()
      generateOceans()
    }
  }
  ```

  </details>

* <a id='multi-line-expression-braces'></a>(<a href='#multi-line-expression-braces'>link</a>) The opening brace following a multi-line expression should wrap to a new line. [![SwiftFormat: wrapMultilineStatementBraces](https://img.shields.io/badge/SwiftFormat-wrapMultilineStatementBraces-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/master/Rules.md#wrapMultilineStatementBraces)

  <details>

  ```swift
  // WRONG
  if
    let star = planet.nearestStar(),
    planet.isInHabitableZone(of: star) {
    planet.terraform()
  }

  class Planet {
    func terraform(
      atmosphereOptions: AtmosphereOptions = .default,
      oceanOptions: OceanOptions = .default) {
      generateAtmosphere(atmosphereOptions)
      generateOceans(oceanOptions)
    }
  }

  // RIGHT
  if
    let star = planet.nearestStar(),
    planet.isInHabitableZone(of: star)
  {
    planet.terraform()
  }

  class Planet {
    func terraform(
      atmosphereOptions: AtmosphereOptions = .default,
      oceanOptions: OceanOptions = .default) 
    {
      generateAtmosphere(atmosphereOptions)
      generateOceans(oceanOptions)
    }
  }
  ```

  </details>

* <a id='whitespace-around-braces'></a>(<a href='#whitespace-around-braces'>link</a>) **Braces should be surrounded by a single whitespace character (either a space, or a newline) on each side.** [![SwiftFormat: spaceInsideBraces](https://img.shields.io/badge/SwiftFormat-spaceInsideBraces-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/master/Rules.md#spaceInsideBraces) [![SwiftFormat: spaceAroundBraces](https://img.shields.io/badge/SwiftFormat-spaceAroundBraces-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/master/Rules.md#spaceAroundBraces)

  <details>

  ```swift
  // WRONG
  struct Planet{
    …
  }

  // WRONG
  if condition{
    …
  }else{
    …
  }

  // RIGHT
  struct Planet {
    …
  }

  // RIGHT
  if condition {
    …
  } else {
    …
  }
  ```

  </details>

* <a id='single-line-comments'></a>(<a href='#single-line-comments'>link</a>) **Comment blocks should use single-line comments (`//` for code comments and `///` for documentation comments)**, rather than multi-line comments (`/* ... */` and `/** ... */`). [![SwiftFormat: blockComments](https://img.shields.io/badge/SwiftFormat-blockComments-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/master/Rules.md#blockComments)

  <details>

  ```swift
  // WRONG

  /**
  * A planet that exists somewhere in the universe.
  *
  * Planets have many properties. For example, the best planets
  * have atmospheres and bodies of water to support life.
  */
  class Planet {
    /**
      Terraforms the planet, by adding an atmosphere and ocean that is hospitable for life.
    */
    func terraform() {
      /* 
      Generate the atmosphere first, before generating the ocean.
      Otherwise, the water will just boil off immediately.
      */
      generateAtmosphere()

      /* Now that we have an atmosphere, it's safe to generate the ocean */
      generateOceans()
    }
  }

  // RIGHT

  /// A planet that exists somewhere in the universe.
  ///
  /// Planets have many properties. For example, the best planets
  /// have atmospheres and bodies of water to support life.
  class Planet {
    /// Terraforms the planet, by adding an atmosphere and ocean that is hospitable for life.
    func terraform() {
      // Generate the atmosphere first, before generating the ocean.
      // Otherwise, the water will just boil off immediately.
      generateAtmosphere()

      // Now that we have an atmosphere, it's safe to generate the ocean
      generateOceans()
    }
  }
  ```

  </details>

### Functions

* <a id='omit-function-void-return'></a>(<a href='#omit-function-void-return'>link</a>) **Omit `Void` return types from function definitions.** [![SwiftFormat: redundantVoidReturnType](https://img.shields.io/badge/SwiftFormat-redundantVoidReturnType-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/master/Rules.md#redundantVoidReturnType)

  <details>

  ```swift
  // WRONG
  func doSomething() -> Void {
    ...
  }

  // RIGHT
  func doSomething() {
    ...
  }
  ```

  </details>

* <a id='long-function-declaration'></a>(<a href='#long-function-declaration'>link</a>) **Separate [long](https://github.com/airbnb/swift#column-width) function declarations with line breaks before each argument label and before the return signature.** Put the open curly brace on the next line so the first executable line doesn't look like it's another parameter. [![SwiftFormat: wrapArguments](https://img.shields.io/badge/SwiftFormat-wrapArguments-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/master/Rules.md#wrapArguments) [![SwiftFormat: braces](https://img.shields.io/badge/SwiftFormat-braces-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/master/Rules.md#braces)

  <details>

  ```swift
  class Universe {

    // WRONG
    func generateStars(at location: Point, count: Int, color: StarColor, withAverageDistance averageDistance: Float) -> String {
      // This is too long and will probably auto-wrap in a weird way
    }

    // WRONG
    func generateStars(at location: Point,
                       count: Int,
                       color: StarColor,
                       withAverageDistance averageDistance: Float) -> String
    {
      // Xcode indents all the arguments
    }

    // WRONG
    func generateStars(
      at location: Point,
      count: Int,
      color: StarColor,
      withAverageDistance averageDistance: Float) -> String {
      populateUniverse() // this line blends in with the argument list
    }

    // WRONG
    func generateStars(
      at location: Point,
      count: Int,
      color: StarColor,
      withAverageDistance averageDistance: Float) throws
      -> String {
      populateUniverse() // this line blends in with the argument list
    }

    // RIGHT
    func generateStars(
      at location: Point,
      count: Int,
      color: StarColor,
      withAverageDistance averageDistance: Float)
      -> String
    {
      populateUniverse()
    }

    // RIGHT
    func generateStars(
      at location: Point,
      count: Int,
      color: StarColor,
      withAverageDistance averageDistance: Float)
      throws -> String
    {
      populateUniverse()
    }
  }
  ```

  </details>

* <a id='long-function-invocation'></a>(<a href='#long-function-invocation'>link</a>) **[Long](https://github.com/airbnb/swift#column-width) function invocations should also break on each argument.** Put the closing parenthesis on the last line of the invocation. [![SwiftFormat: wrapArguments](https://img.shields.io/badge/SwiftFormat-wrapArguments-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/master/Rules.md#wrapArguments)

  <details>

  ```swift
  // WRONG
  universe.generateStars(at: location, count: 5, color: starColor, withAverageDistance: 4)

  // WRONG
  universe.generateStars(at: location,
                         count: 5,
                         color: starColor,
                         withAverageDistance: 4)

  // WRONG
  universe.generateStars(
    at: location,
    count: 5,
    color: starColor,
    withAverageDistance: 4
  )

  // WRONG
  universe.generate(5,
    .stars,
    at: location)

  // RIGHT
  universe.generateStars(
    at: location,
    count: 5,
    color: starColor,
    withAverageDistance: 4)

  // RIGHT
  universe.generate(
    5,
    .stars,
    at: location)
  ```

  </details>

* <a id='unused-function-parameter-naming'></a>(<a href='#unused-function-parameter-naming'>link</a>) **Name unused function parameters as underscores (`_`).** [![SwiftFormat: unusedArguments](https://img.shields.io/badge/SwiftFormat-unusedArguments-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/master/Rules.md#unusedArguments)

    <details>

    #### Why?
    Naming unused function parameters as underscores makes it more clear when the parameter is unused within the function body.
    This can make it easier to catch subtle logical errors, and can highlight opportunities to simplify method signatures.

    ```swift
    // WRONG

    // In this method, the `newContext` parameter is unused.
    // This is actually a logical error, and is easy to miss, but compiles without warning.
    func withContext(_ newContext: Context) {
      var updatedValue = self
      updatedValue.context = context
      return updatedValue  
    }

    // In this method, the `color` parameter is unused.
    // Is this a logical error (e.g. should it be passed through to the `universe.generateStars` method call),
    // or is this an unused argument that should be removed from the method signature?
    func generateUniverseWithStars(
      at location: Point,
      count: Int,
      color: StarColor,
      withAverageDistance averageDistance: Float)
    {
      let universe = generateUniverse()
      universe.generateStars(
        at: location,
        count: count,
        withAverageDistance: averageDistance)
    }
    ```

    ```swift
    // RIGHT

    // Automatically reformatting the unused parameter to be an underscore
    // makes it more clear that the parameter is unused, which makes it
    // easier to spot the logical error.
    func withContext(_: Context) {
      var updatedValue = self
      updatedValue.context = context
      return updatedValue  
    }

    // The underscore makes it more clear that the `color` parameter is unused.
    // This method argument can either be removed if truly unnecessary,
    // or passed through to `universe.generateStars` to correct the logical error.
    func generateUniverseWithStars(
      at location: Point,
      count: Int,
      color _: StarColor,
      withAverageDistance averageDistance: Float)
    {
      let universe = generateUniverse()
      universe.generateStars(
        at: location,
        count: count,
        withAverageDistance: averageDistance)
    }
    ```

    </details>

### Closures

* <a id='favor-void-closure-return'></a>(<a href='#favor-void-closure-return'>link</a>) **Favor `Void` return types over `()` in closure declarations.** If you must specify a `Void` return type in a function declaration, use `Void` rather than `()` to improve readability. [![SwiftLint: void_return](https://img.shields.io/badge/SwiftLint-void__return-007A87.svg)](https://realm.github.io/SwiftLint/void_return)

  <details>

  ```swift
  // WRONG
  func method(completion: () -> ()) {
    ...
  }

  // RIGHT
  func method(completion: () -> Void) {
    ...
  }
  ```

  </details>

* <a id='unused-closure-parameter-naming'></a>(<a href='#unused-closure-parameter-naming'>link</a>) **Name unused closure parameters as underscores (`_`).** [![SwiftFormat: unusedArguments](https://img.shields.io/badge/SwiftFormat-unusedArguments-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/master/Rules.md#unusedArguments)

    <details>

    #### Why?
    Naming unused closure parameters as underscores reduces the cognitive overhead required to read
    closures by making it obvious which parameters are used and which are unused.

    ```swift
    // WRONG
    someAsyncThing() { argument1, argument2, argument3 in
      print(argument3)
    }

    // RIGHT
    someAsyncThing() { _, _, argument3 in
      print(argument3)
    }
    ```

    </details>

* <a id='closure-brace-spacing'></a>(<a href='#closure-brace-spacing'>link</a>) **Closures should have a single space or newline inside each brace.** Trailing closures should additionally have a single space or newline outside each brace. [![SwiftFormat: spaceInsideBraces](https://img.shields.io/badge/SwiftFormat-spaceInsideBraces-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/master/Rules.md#spaceInsideBraces) [![SwiftFormat: spaceAroundBraces](https://img.shields.io/badge/SwiftFormat-spaceAroundBraces-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/master/Rules.md#spaceAroundBraces)

  <details>

  ```swift
  // WRONG
  let evenSquares = numbers.filter{$0.isMultiple(of: 2)}.map{  $0 * $0  }

  // RIGHT
  let evenSquares = numbers.filter { $0.isMultiple(of: 2) }.map { $0 * $0 }

  // WRONG
  let evenSquares = numbers.filter( { $0.isMultiple(of: 2) } ).map( { $0 * $0 } )

  // RIGHT
  let evenSquares = numbers.filter({ $0.isMultiple(of: 2) }).map({ $0 * $0 })

  // WRONG
  let evenSquares = numbers
    .filter{ 
      $0.isMultiple(of: 2) 
    }
    .map{ 
      $0 * $0 
    }

  // RIGHT
  let evenSquares = numbers
    .filter {
      $0.isMultiple(of: 2) 
    }
    .map {
      $0 * $0 
    }
  ```

  </details>

* <a id='omit-closure-void-return'></a>(<a href='#omit-closure-void-return'>link</a>) **Omit `Void` return types from closure expressions.** [![SwiftFormat: redundantVoidReturnType](https://img.shields.io/badge/SwiftFormat-redundantVoidReturnType-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/master/Rules.md#redundantVoidReturnType)

  <details>

  ```swift
  // WRONG
  someAsyncThing() { argument -> Void in
    ...
  }

  // RIGHT
  someAsyncThing() { argument in
    ...
  }
  ```

### Operators

* <a id='infix-operator-spacing'></a>(<a href='#infix-operator-spacing'>link</a>) **Infix operators should have a single space on either side.** Prefer parenthesis to visually group statements with many operators rather than varying widths of whitespace. This rule does not apply to range operators (e.g. `1...3`) and postfix or prefix operators (e.g. `guest?` or `-1`). [![SwiftLint: operator_usage_whitespace](https://img.shields.io/badge/SwiftLint-operator__usage__whitespace-007A87.svg)](https://realm.github.io/SwiftLint/operator_usage_whitespace)

  <details>

  ```swift
  // WRONG
  let capacity = 1+2
  let capacity = currentCapacity   ?? 0
  let mask = (UIAccessibilityTraitButton|UIAccessibilityTraitSelected)
  let capacity=newCapacity
  let latitude = region.center.latitude - region.span.latitudeDelta/2.0

  // RIGHT
  let capacity = 1 + 2
  let capacity = currentCapacity ?? 0
  let mask = (UIAccessibilityTraitButton | UIAccessibilityTraitSelected)
  let capacity = newCapacity
  let latitude = region.center.latitude - (region.span.latitudeDelta / 2.0)
  ```

  </details>

* <a id='long-ternary-operator-expressions'></a>(<a href='#long-ternary-operator-expressions'>link</a>) **[Long](https://github.com/airbnb/swift#column-width) ternary operator expressions should wrap before the `?` and before the `:`**, putting each conditional branch on a separate line. [![SwiftFormat: wrap](https://img.shields.io/badge/SwiftFormat-wrap-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/master/Rules.md#wrap)

  <details>

  ```swift
  // WRONG (too long)
  let destinationPlanet = solarSystem.hasPlanetsInHabitableZone ? solarSystem.planetsInHabitableZone.first : solarSystem.uninhabitablePlanets.first

  // WRONG (naive wrapping)
  let destinationPlanet = solarSystem.hasPlanetsInHabitableZone ? solarSystem.planetsInHabitableZone.first :
    solarSystem.uninhabitablePlanets.first

  // WRONG (unbalanced operators)
  let destinationPlanet = solarSystem.hasPlanetsInHabitableZone ?
    solarSystem.planetsInHabitableZone.first :
    solarSystem.uninhabitablePlanets.first

  // RIGHT
  let destinationPlanet = solarSystem.hasPlanetsInHabitableZone
    ? solarSystem.planetsInHabitableZone.first
    : solarSystem.uninhabitablePlanets.first
   ```

  </details>

**[⬆ back to top](#table-of-contents)**

## Patterns

* <a id='implicitly-unwrapped-optionals'></a>(<a href='#implicitly-unwrapped-optionals'>link</a>) **Prefer initializing properties at `init` time whenever possible, rather than using implicitly unwrapped optionals.**  A notable exception is UIViewController's `view` property. [![SwiftLint: implicitly_unwrapped_optional](https://img.shields.io/badge/SwiftLint-implicitly__unwrapped__optional-007A87.svg)](https://realm.github.io/SwiftLint/implicitly_unwrapped_optional)

  <details>

  ```swift
  // WRONG
  class MyClass {

    init() {
      super.init()
      someValue = 5
    }

    var someValue: Int!
  }

  // RIGHT
  class MyClass {

    init() {
      someValue = 0
      super.init()
    }

    var someValue: Int
  }
  ```

  </details>

* <a id='time-intensive-init'></a>(<a href='#time-intensive-init'>link</a>) **Avoid performing any meaningful or time-intensive work in `init()`.** Avoid doing things like opening database connections, making network requests, reading large amounts of data from disk, etc. Create something like a `start()` method if these things need to be done before an object is ready for use.

* <a id='complex-property-observers'></a>(<a href='#complex-property-observers'>link</a>) **Extract complex property observers into methods.** This reduces nestedness, separates side-effects from property declarations, and makes the usage of implicitly-passed parameters like `oldValue` explicit.

  <details>

  ```swift
  // WRONG
  class TextField {
    var text: String? {
      didSet {
        guard oldValue != text else {
          return
        }

        // Do a bunch of text-related side-effects.
      }
    }
  }

  // RIGHT
  class TextField {
    var text: String? {
      didSet { textDidUpdate(from: oldValue) }
    }

    private func textDidUpdate(from oldValue: String?) {
      guard oldValue != text else {
        return
      }

      // Do a bunch of text-related side-effects.
    }
  }
  ```

  </details>

* <a id='complex-callback-block'></a>(<a href='#complex-callback-block'>link</a>) **Extract complex callback blocks into methods**. This limits the complexity introduced by weak-self in blocks and reduces nestedness. If you need to reference self in the method call, make use of `guard` to unwrap self for the duration of the callback.

  <details>

  ```swift
  //WRONG
  class MyClass {

    func request(completion: () -> Void) {
      API.request() { [weak self] response in
        if let self = self {
          // Processing and side effects
        }
        completion()
      }
    }
  }

  // RIGHT
  class MyClass {

    func request(completion: () -> Void) {
      API.request() { [weak self] response in
        guard let self = self else { return }
        self.doSomething(with: self.property, response: response)
        completion()
      }
    }

    func doSomething(with nonOptionalParameter: SomeClass, response: SomeResponseClass) {
      // Processing and side effects
    }
  }
  ```

  </details>

* <a id='guards-at-top'></a>(<a href='#guards-at-top'>link</a>) **Prefer using `guard` at the beginning of a scope.**

  <details>

  #### Why?
  It's easier to reason about a block of code when all `guard` statements are grouped together at the top rather than intermixed with business logic.

  </details>

* <a id='limit-access-control'></a>(<a href='#limit-access-control'>link</a>) **Access control should be at the strictest level possible.** Prefer `public` to `open` and `private` to `fileprivate` unless you need that behavior. [![SwiftFormat: redundantFileprivate](https://img.shields.io/badge/SwiftFormat-redundantFileprivate-008489.svg)](https://github.com/nicklockwood/SwiftFormat/blob/master/Rules.md#redundantFileprivate)

  <details>

  ```swift
  // WRONG
  public struct Spaceship {
    // WRONG: `engine` is used in `extension Spaceship` below,
    // but extensions in the same file can access `private` members.
    fileprivate let engine: AntimatterEngine

    // WRONG: `hull` is not used by any other type, so `fileprivate` is unnecessary. 
    fileprivate let hull: Hull

    // RIGHT: `navigation` is used in `extension Pilot` below,
    // so `fileprivate` is necessary here.
    fileprivate let navigation: SpecialRelativityNavigationService
  }

  extension Spaceship {
    public func blastOff() {
      engine.start()
    }
  }

  extension Pilot {
    public func chartCourse() {
      spaceship.navigation.course = .andromedaGalaxy
      spaceship.blastOff()
    }
  }
  ```

  ```swift
  // RIGHT
  public struct Spaceship {
    fileprivate let navigation: SpecialRelativityNavigationService
    private let engine: AntimatterEngine
    private let hull: Hull
  }

  extension Spaceship {
    public func blastOff() {
      engine.start()
    }
  }
  
  extension Pilot {
    public func chartCourse() {
      spaceship.navigation.course = .andromedaGalaxy
      spaceship.blastOff()
    }
  }
  ```

* <a id='avoid-global-functions'></a>(<a href='#avoid-global-functions'>link</a>) **Avoid global functions whenever possible.** Prefer methods within type definitions.

  <details>

  ```swift
  // WRONG
  func age(of person, bornAt timeInterval) -> Int {
    // ...
  }

  func jump(person: Person) {
    // ...
  }

  // RIGHT
  class Person {
    var bornAt: TimeInterval

    var age: Int {
      // ...
    }

    func jump() {
      // ...
    }
  }
  ```

  </details>

* <a id='namespace-using-enums'></a>(<a href='#namespace-using-enums'>link</a>) **Use caseless `enum`s for organizing `public` or `internal` constants and functions into namespaces.** [![SwiftFormat: enumNamespaces](https://img.shields.io/badge/SwiftFormat-enumNamespaces-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/master/Rules.md#enumNamespaces)
  * Avoid creating non-namespaced global constants and functions.
  * Feel free to nest namespaces where it adds clarity.
  * `private` globals are permitted, since they are scoped to a single file and do not pollute the global namespace. Consider placing private globals in an `enum` namespace to match the guidelines for other declaration types.

  <details>

  #### Why?
  Caseless `enum`s work well as namespaces because they cannot be instantiated, which matches their intent.

  ```swift
  enum Environment {

    enum Earth {
      static let gravity = 9.8
    }

    enum Moon {
      static let gravity = 1.6
    }
  }
  ```

  </details>

* <a id='auto-enum-values'></a>(<a href='#auto-enum-values'>link</a>) **Use Swift's automatic enum values unless they map to an external source.** Add a comment explaining why explicit values are defined. [![SwiftFormat: redundantRawValues](https://img.shields.io/badge/SwiftFormat-redundantRawValues-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/master/Rules.md#redundantRawValues)

  <details>

  #### Why?
  To minimize user error, improve readability, and write code faster, rely on Swift's automatic enum values. If the value maps to an external source (e.g. it's coming from a network request) or is persisted across binaries, however, define the values explicity, and document what these values are mapping to.

  This ensures that if someone adds a new value in the middle, they won't accidentally break things.

  ```swift
  // WRONG
  enum ErrorType: String {
    case error = "error"
    case warning = "warning"
  }

  enum UserType: String {
    case owner
    case manager
    case member
  }

  enum Planet: Int {
    case mercury = 0
    case venus = 1
    case earth = 2
    case mars = 3
    case jupiter = 4
    case saturn = 5
    case uranus = 6
    case neptune = 7
  }

  enum ErrorCode: Int {
    case notEnoughMemory
    case invalidResource
    case timeOut
  }

  // RIGHT
  enum ErrorType: String {
    case error
    case warning
  }

  /// These are written to a logging service. Explicit values ensure they're consistent across binaries.
  // swiftformat:disable redundantRawValues
  enum UserType: String {
    case owner = "owner"
    case manager = "manager"
    case member = "member"
  }
  // swiftformat:enable redundantRawValues

  enum Planet: Int {
    case mercury
    case venus
    case earth
    case mars
    case jupiter
    case saturn
    case uranus
    case neptune
  }

  /// These values come from the server, so we set them here explicitly to match those values.
  enum ErrorCode: Int {
    case notEnoughMemory = 0
    case invalidResource = 1
    case timeOut = 2
  }
  ```

  </details>

* <a id='semantic-optionals'></a>(<a href='#semantic-optionals'>link</a>) **Use optionals only when they have semantic meaning.**

* <a id='prefer-immutable-values'></a>(<a href='#prefer-immutable-values'>link</a>) **Prefer immutable values whenever possible.** Use `map` and `compactMap` instead of appending to a new collection. Use `filter` instead of removing elements from a mutable collection.

  <details>

  #### Why?
  Mutable variables increase complexity, so try to keep them in as narrow a scope as possible.

  ```swift
  // WRONG
  var results = [SomeType]()
  for element in input {
    let result = transform(element)
    results.append(result)
  }

  // RIGHT
  let results = input.map { transform($0) }
  ```

  ```swift
  // WRONG
  var results = [SomeType]()
  for element in input {
    if let result = transformThatReturnsAnOptional(element) {
      results.append(result)
    }
  }

  // RIGHT
  let results = input.compactMap { transformThatReturnsAnOptional($0) }
  ```

  </details>

* <a id='prefer-immutable-statics'></a>(<a href='#prefer-immutable-statics'>link</a>) **Prefer immutable or computed static properties over mutable ones whenever possible.** Use stored `static let` properties or computed `static var` properties over stored `static var`s properties whenever possible, as stored `static var` properties are global mutable state.

  <details>

  #### Why?
  Global mutable state increases complexity and makes it harder to reason about the behavior of applications. It should be avoided when possible.

  ```swift
  // WRONG
  enum Fonts {
    static var title = UIFont(…)
  }

  // RIGHT
  enum Fonts {
    static let title = UIFont(…)
  }
  ```

  ```swift
  // WRONG
  struct FeatureState {
    var count: Int

    static var initial = FeatureState(count: 0)
  }

  // RIGHT
  struct FeatureState {
    var count: Int

    static var initial: FeatureState {
      // Vend static properties that are cheap to compute
      FeatureState(count: 0)
    }
  }
  ```

  </details>

* <a id='preconditions-and-asserts'></a>(<a href='#preconditions-and-asserts'>link</a>) **Handle an unexpected but recoverable condition with an `assert` method combined with the appropriate logging in production. If the unexpected condition is not recoverable, prefer a `precondition` method or `fatalError()`.** This strikes a balance between crashing and providing insight into unexpected conditions in the wild. Only prefer `fatalError` over a `precondition` method when the failure message is dynamic, since a `precondition` method won't report the message in the crash report. [![SwiftLint: fatal_error_message](https://img.shields.io/badge/SwiftLint-fatal__error__message-007A87.svg)](https://realm.github.io/SwiftLint/fatal_error_message)

  <details>

  ```swift
  func didSubmitText(_ text: String) {
    // It's unclear how this was called with an empty string; our custom text field shouldn't allow this.
    // This assert is useful for debugging but it's OK if we simply ignore this scenario in production.
    guard !text.isEmpty else {
      assertionFailure("Unexpected empty string")
      return
    }
    // ...
  }

  func transformedItem(atIndex index: Int, from items: [Item]) -> Item {
    precondition(index >= 0 && index < items.count)
    // It's impossible to continue executing if the precondition has failed.
    // ...
  }

  func makeImage(name: String) -> UIImage {
    guard let image = UIImage(named: name, in: nil, compatibleWith: nil) else {
      fatalError("Image named \(name) couldn't be loaded.")
      // We want the error message so we know the name of the missing image.
    }
    return image
  }
  ```

  </details>

* <a id='static-type-methods-by-default'></a>(<a href='#static-type-methods-by-default'>link</a>) **Default type methods to `static`.**

  <details>

  #### Why?
  If a method needs to be overridden, the author should opt into that functionality by using the `class` keyword instead.

  ```swift
  // WRONG
  class Fruit {
    class func eatFruits(_ fruits: [Fruit]) { ... }
  }

  // RIGHT
  class Fruit {
    static func eatFruits(_ fruits: [Fruit]) { ... }
  }
  ```

  </details>

* <a id='final-classes-by-default'></a>(<a href='#final-classes-by-default'>link</a>) **Default classes to `final`.**

  <details>

  #### Why?
  If a class needs to be overridden, the author should opt into that functionality by omitting the `final` keyword.

  ```swift
  // WRONG
  class SettingsRepository {
    // ...
  }

  // RIGHT
  final class SettingsRepository {
    // ...
  }
  ```

  </details>

* <a id='switch-never-default'></a>(<a href='#switch-never-default'>link</a>) **Never use the `default` case when `switch`ing over an enum.**

  <details>

  #### Why?
  Enumerating every case requires developers and reviewers have to consider the correctness of every switch statement when new cases are added.

  ```swift
  // WRONG
  switch anEnum {
  case .a:
    // Do something
  default:
    // Do something else.
  }

  // RIGHT
  switch anEnum {
  case .a:
    // Do something
  case .b, .c:
    // Do something else.
  }
  ```

  </details>

* <a id='optional-nil-check'></a>(<a href='#optional-nil-check'>link</a>) **Check for nil rather than using optional binding if you don't need to use the value.** [![SwiftLint: unused_optional_binding](https://img.shields.io/badge/SwiftLint-unused_optional_binding-007A87.svg)](https://realm.github.io/SwiftLint/unused_optional_binding)

  <details>

  #### Why?
  Checking for nil makes it immediately clear what the intent of the statement is. Optional binding is less explicit.

  ```swift
  var thing: Thing?

  // WRONG
  if let _ = thing {
    doThing()
  }

  // RIGHT
  if thing != nil {
    doThing()
  }
  ```

  </details>

* <a id='omit-return'></a>(<a href='#omit-return'>link</a>) **Omit the `return` keyword when not required by the language.** [![SwiftFormat: redundantReturn](https://img.shields.io/badge/SwiftFormat-redundantReturn-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/master/Rules.md#redundantReturn)

  <details>

  ```swift
  // WRONG
  ["1", "2", "3"].compactMap { return Int($0) }

  var size: CGSize {
    return CGSize(
      width: 100.0,
      height: 100.0)
  }

  func makeInfoAlert(message: String) -> UIAlertController {
    return UIAlertController(
      title: "ℹ️ Info",
      message: message,
      preferredStyle: .alert)
  }

  // RIGHT
  ["1", "2", "3"].compactMap { Int($0) }

  var size: CGSize {
    CGSize(
      width: 100.0,
      height: 100.0)
  }

  func makeInfoAlert(message: String) -> UIAlertController {
    UIAlertController(
      title: "ℹ️ Info",
      message: message,
      preferredStyle: .alert)
  }
  ```

  </details>

* <a id='use-anyobject'></a>(<a href='#use-anyobject'>link</a>) **Use `AnyObject` instead of `class` in protocol definitions.** [![SwiftFormat: anyObjectProtocol](https://img.shields.io/badge/SwiftFormat-anyObjectProtocol-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/master/Rules.md#anyobjectprotocol)

  <details>

  #### Why?

  [SE-0156](https://github.com/apple/swift-evolution/blob/master/proposals/0156-subclass-existentials.md]), which introduced support for using the `AnyObject` keyword as a protocol constraint, recommends preferring `AnyObject` over `class`:

  > This proposal merges the concepts of `class` and `AnyObject`, which now have the same meaning: they represent an existential for classes. To get rid of the duplication, we suggest only keeping `AnyObject` around. To reduce source-breakage to a minimum, `class` could be redefined as `typealias class = AnyObject` and give a deprecation warning on class for the first version of Swift this proposal is implemented in. Later, `class` could be removed in a subsequent version of Swift.

  ```swift
  // WRONG
  protocol Foo: class {}

  // RIGHT
  protocol Foo: AnyObject {}
  ```

  </details>

* <a id='extension-access-control'></a>(<a href='#extension-access-control'>link</a>) **Specify the access control for each declaration in an extension individually.** [![SwiftFormat: extensionAccessControl](https://img.shields.io/badge/SwiftFormat-extensionAccessControl-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/master/Rules.md#extensionaccesscontrol)

  <details>

  #### Why?

  Specifying the access control on the declaration itself helps engineers more quickly determine the access control level of an individual declaration.

  ```swift
  // WRONG
  public extension Universe {
    // This declaration doesn't have an explicit access control level.
    // In all other scopes, this would be an internal function,
    // but because this is in a public extension, it's actually a public function.
    func generateGalaxy() { }
  }

  // WRONG
  private extension Spaceship {
    func enableHyperdrive() { }
  }

  // RIGHT
  extension Universe {
    // It is immediately obvious that this is a public function,
    // even if the start of the `extension Universe` scope is off-screen.
    public func generateGalaxy() { }
  }

  // RIGHT
  extension Spaceship {
    // Recall that a private extension actually has fileprivate semantics,
    // so a declaration in a private extension is fileprivate by default.
    fileprivate func enableHyperdrive() { }
  }
  ```

  </details>

* <a id='no-direct-standard-out-logs'></a>(<a href='#no-direct-standard-out-logs'>link</a>) **Prefer dedicated logging systems like [`os_log`](https://developer.apple.com/documentation/os/logging) or [`swift-log`](https://github.com/apple/swift-log) over writing directly to standard out using `print(…)`, `debugPrint(…)`, or `dump(…)`.**

  <details>

  #### Why?
  All log messages should flow into intermediate logging systems that can direct messages to the correct destination(s) and potentially filter messages based on the app's environment or configuration. `print(…)`, `debugPrint(…)`, or `dump(…)` will write all messages directly to standard out in all app configurations and can potentially leak personally identifiable information (PII).

  </details>

* <a id='avoid-redundant-closures'></a>(<a href='#avoid-redundant-closures'>link</a>) **Avoid single-expression closures that are always called immediately**. Instead, prefer inlining the expression. [![SwiftFormat: redundantClosure](https://img.shields.io/badge/SwiftFormat-redundantClosure-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/master/Rules.md#redundantClosure)

  <details>

  ```swift
  // WRONG
  lazy var universe: Universe = { 
    Universe() 
  }()

  lazy var stars = {
    universe.generateStars(
      at: location,
      count: 5,
      color: starColor,
      withAverageDistance: 4)
  }()

  // RIGHT
  lazy var universe = Universe() 

  lazy var stars = universe.generateStars(
    at: location,
    count: 5,
    color: starColor,
    withAverageDistance: 4)
  ```

  </details>

* <a id='redundant-get'></a>(<a href='#redundant-get'>link</a>) **Omit the `get` clause from a computed property declaration that doesn't also have a `set`, `willSet`, or `didSet` clause.** [![SwiftFormat: redundantGet](https://img.shields.io/badge/SwiftFormat-redundantGet-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/master/Rules.md#redundantGet)

    <details>

    ```swift
    // WRONG
    var universe: Universe {
      get {
        Universe()
      }
    }

    // RIGHT
    var universe: Universe {
      Universe()
    }

    // RIGHT
    var universe: Universe {
      get { multiverseService.current }
      set { multiverseService.current = newValue }
    }
    ```

    </details>

**[⬆ back to top](#table-of-contents)**

## File Organization

* <a id='alphabetize-and-deduplicate-imports'></a>(<a href='#alphabetize-and-deduplicate-imports'>link</a>) **Alphabetize and deduplicate module imports within a file. Place all imports at the top of the file below the header comments. Do not add additional line breaks between import statements. Add a single empty line before the first import and after the last import.** [![SwiftFormat: sortedImports](https://img.shields.io/badge/SwiftFormat-sortedImports-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/master/Rules.md#sortedImports) [![SwiftFormat: duplicateImports](https://img.shields.io/badge/SwiftFormat-duplicateImports-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/master/Rules.md#duplicateImports)

  <details>

  #### Why?
  - A standard organization method helps engineers more quickly determine which modules a file depends on.
  - Duplicated import statements have no effect and should be removed for clarity.

  ```swift
  // WRONG

  //  Copyright © 2018 Airbnb. All rights reserved.
  //
  import DLSPrimitives
  import Constellation
  import Constellation
  import Epoxy

  import Foundation

  //RIGHT

  //  Copyright © 2018 Airbnb. All rights reserved.
  //

  import Constellation
  import DLSPrimitives
  import Epoxy
  import Foundation
  ```

  </details>

  _Exception: `@testable import` should be grouped after the regular import and separated by an empty line._

  <details>

  ```swift
  // WRONG

  //  Copyright © 2018 Airbnb. All rights reserved.
  //

  import DLSPrimitives
  @testable import Epoxy
  import Foundation
  import Nimble
  import Quick

  //RIGHT

  //  Copyright © 2018 Airbnb. All rights reserved.
  //

  import DLSPrimitives
  import Foundation
  import Nimble
  import Quick

  @testable import Epoxy
  ```

  </details>

* <a id='limit-consecutive-whitespace'></a><a id='limit-vertical-whitespace'></a>(<a href='#limit-consecutive-whitespace'>link</a>) **Limit consecutive whitespace to one blank line or space (excluding indentation).** Favor the following formatting guidelines over whitespace of varying heights or widths. [![SwiftLint: vertical_whitespace](https://img.shields.io/badge/SwiftLint-vertical__whitespace-007A87.svg)](https://realm.github.io/SwiftLint/vertical_whitespace) [![SwiftFormat: consecutiveSpaces](https://img.shields.io/badge/SwiftFormat-consecutiveSpaces-008489.svg)](https://github.com/nicklockwood/SwiftFormat/blob/master/Rules.md#consecutiveSpaces)

  <details>

  ```swift
  // WRONG
  struct Planet {

    let mass:          Double
    let hasAtmosphere: Bool


    func distance(to: Planet) { }

  }

  // RIGHT
  struct Planet {

    let mass: Double
    let hasAtmosphere: Bool

    func distance(to: Planet) { }

  }
  ```

  </details>


* <a id='newline-at-eof'></a>(<a href='#newline-at-eof'>link</a>) **Files should end in a newline.** [![SwiftLint: trailing_newline](https://img.shields.io/badge/SwiftLint-trailing__newline-007A87.svg)](https://realm.github.io/SwiftLint/trailing_newline)

* <a id='newline-between-scope-siblings'></a>(<a href='#newline-between-scope-siblings'>link</a>) **Declarations that include scopes spanning multiple lines should be separated from adjacent declarations in the same scope by a newline.** Insert a single blank line between multi-line scoped declarations (e.g. types, extensions, functions, computed properties, etc.) and other declarations at the same indentation level. [![SwiftFormat: blankLinesBetweenScopes](https://img.shields.io/badge/SwiftFormat-blankLinesBetweenScopes-008489.svg)](https://github.com/nicklockwood/SwiftFormat/blob/master/Rules.md#blankLinesBetweenScopes)

  <details>

  #### Why?
  Dividing scoped declarations from other declarations at the same scope visually separates them, making adjacent declarations easier to differentiate from the scoped declaration.

  ```swift
  // WRONG
  struct SolarSystem {
    var numberOfPlanets: Int {
      …
    }
    func distance(to: SolarSystem) -> AstronomicalUnit {
      …
    }
  }
  struct Galaxy {
    func distance(to: Galaxy) -> AstronomicalUnit {
      …
    }
    func contains(_ solarSystem: SolarSystem) -> Bool {
      …
    }
  }

  // RIGHT
  struct SolarSystem {
    var numberOfPlanets: Int {
      …
    }

    func distance(to: SolarSystem) -> AstronomicalUnit {
      …
    }
  }

  struct Galaxy {
    func distance(to: Galaxy) -> AstronomicalUnit {
      …
    }

    func contains(_ solarSystem: SolarSystem) -> Bool {
      …
    }
  }
  ```

  </details>


* <a id='mark-types-and-extensions'></a>(<a href='#mark-types-and-extensions'>link</a>) **Each type and extension which implements a conformance should be preceded by a `MARK` comment.** [![SwiftFormat: markTypes](https://img.shields.io/badge/SwiftFormat-markTypes-008489.svg)](https://github.com/nicklockwood/SwiftFormat/blob/master/Rules.md#markTypes)
  * Types should be preceded by a `// MARK: - TypeName` comment.
  * Extensions that add a conformance should be preceded by a `// MARK: - TypeName + ProtocolName` comment.
  * Extensions that immediately follow the type being extended should omit that type's name and instead use `// MARK: ProtocolName`.
  * If there is only one type or extension in a file, the `MARK` comment can be omitted.
  * If the extension in question is empty (e.g. has no declarations in its body), the `MARK` comment can be omitted.
  * For extensions that do not add new conformances, consider adding a `MARK` with a descriptive comment.

  <details>

  ```swift
  // MARK: - GalaxyView

  final class GalaxyView: UIView { … }

  // MARK: ContentConfigurableView

  extension GalaxyView: ContentConfigurableView { … }

  // MARK: - Galaxy + SpaceThing, NamedObject

  extension Galaxy: SpaceThing, NamedObject { … }
  ```

  </details>

* <a id='marks-within-types'></a>(<a href='#marks-within-types'>link</a>) **Use `// MARK:` to separate the contents of type definitions and extensions into the sections listed below, in order.** All type definitions and extensions should be divided up in this consistent way, allowing a reader of your code to easily jump to what they are interested in. [![SwiftFormat: organizeDeclarations](https://img.shields.io/badge/SwiftFormat-organizeDeclarations-008489.svg)](https://github.com/nicklockwood/SwiftFormat/blob/master/Rules.md#organizeDeclarations)
  * `// MARK: Lifecycle` for `init` and `deinit` methods.
  * `// MARK: Open` for `open` properties and methods.
  * `// MARK: Public` for `public` properties and methods.
  * `// MARK: Internal` for `internal` properties and methods.
  * `// MARK: Fileprivate` for `fileprivate` properties and methods.
  * `// MARK: Private` for `private` properties and methods.
  * If the type in question is an enum, its cases should go above the first `// MARK:`.
  * Do not subdivide each of these sections into subsections, as it makes the method dropdown more cluttered and therefore less useful. Instead, group methods by functionality and use smart naming to make clear which methods are related. If there are enough methods that sub-sections seem necessary, consider refactoring your code into multiple types.
  * If all of the type or extension's definitions belong to the same category (e.g. the type or extension only consists of `internal` properties), it is OK to omit the `// MARK:`s.
  * If the type in question is a simple value type (e.g. fewer than 20 lines), it is OK to omit the `// MARK:`s, as it would hurt legibility.

* <a id='subsection-organization'></a>(<a href='#subsection-organization'>link</a>) **Within each top-level section, place content in the following order.** This allows a new reader of your code to more easily find what they are looking for. [![SwiftFormat: organizeDeclarations](https://img.shields.io/badge/SwiftFormat-organizeDeclarations-008489.svg)](https://github.com/nicklockwood/SwiftFormat/blob/master/Rules.md#organizeDeclarations)
  * Nested types and typealiases
  * Static properties
  * Class properties
  * Instance properties
  * Static methods
  * Class methods
  * Instance methods

* <a id='newline-between-subsections'></a>(<a href='#newline-between-subsections'>link</a>) **Add empty lines between property declarations of different kinds.** (e.g. between static properties and instance properties.) [![SwiftFormat: organizeDeclarations](https://img.shields.io/badge/SwiftFormat-organizeDeclarations-008489.svg)](https://github.com/nicklockwood/SwiftFormat/blob/master/Rules.md#organizeDeclarations)

  <details>

  ```swift
  // WRONG
  static let gravityEarth: CGFloat = 9.8
  static let gravityMoon: CGFloat = 1.6
  var gravity: CGFloat

  // RIGHT
  static let gravityEarth: CGFloat = 9.8
  static let gravityMoon: CGFloat = 1.6

  var gravity: CGFloat
  ```

  </details>

* <a id='computed-properties-at-end'></a>(<a href='#computed-properties-at-end'>link</a>) **Computed properties and properties with property observers should appear at the end of the set of declarations of the same kind.** (e.g. instance properties.) [![SwiftFormat: organizeDeclarations](https://img.shields.io/badge/SwiftFormat-organizeDeclarations-008489.svg)](https://github.com/nicklockwood/SwiftFormat/blob/master/Rules.md#organizeDeclarations)

  <details>

  ```swift
  // WRONG
  var atmosphere: Atmosphere {
    didSet {
      print("oh my god, the atmosphere changed")
    }
  }
  var gravity: CGFloat

  // RIGHT
  var gravity: CGFloat
  var atmosphere: Atmosphere {
    didSet {
      print("oh my god, the atmosphere changed")
    }
  }
  ```

  </details>

**[⬆ back to top](#table-of-contents)**

## Objective-C Interoperability

* <a id='prefer-pure-swift-classes'></a>(<a href='#prefer-pure-swift-classes'>link</a>) **Prefer pure Swift classes over subclasses of NSObject.** If your code needs to be used by some Objective-C code, wrap it to expose the desired functionality. Use `@objc` on individual methods and variables as necessary rather than exposing all API on a class to Objective-C via `@objcMembers`.

  <details>

  ```swift
  class PriceBreakdownViewController {

    private let acceptButton = UIButton()

    private func setUpAcceptButton() {
      acceptButton.addTarget(
        self,
        action: #selector(didTapAcceptButton),
        forControlEvents: .touchUpInside)
    }

    @objc
    private func didTapAcceptButton() {
      // ...
    }
  }
  ```

  </details>

**[⬆ back to top](#table-of-contents)**

## Contributors

  - [View Contributors](https://github.com/airbnb/swift/graphs/contributors)

**[⬆ back to top](#table-of-contents)**

## Amendments

We encourage you to fork this guide and change the rules to fit your team’s style guide. Below, you may list some amendments to the style guide. This allows you to periodically update your style guide without having to deal with merge conflicts.

**[⬆ back to top](#table-of-contents)**
