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

* <a id='column-width'></a>(<a href='#column-width'>link</a>) **Each line should have a maximum column width of 100 characters.**

  <details>

  #### Why?
  Due to larger screen sizes, we have opted to choose a page guide greater than 80

  </details>

* <a id='spaces-over-tabs'></a>(<a href='#spaces-over-tabs'>link</a>) **Use 2 spaces to indent lines.**

* <a id='trailing-whitespace'></a>(<a href='#trailing-whitespace'>link</a>) **Trim trailing whitespace in all lines.** [![SwiftFormat: trailingSpace](https://img.shields.io/badge/SwiftFormat-trailingSpace-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/master/Rules.md#trailingSpace)

**[⬆ back to top](#table-of-contents)**

## Naming

* <a id='use-camel-case'></a>(<a href='#use-camel-case'>link</a>) **Use PascalCase for type and protocol names, and lowerCamelCase for everything else.** [![SwiftLint: type_name](https://img.shields.io/badge/SwiftLint-type__name-007A87.svg)](https://github.com/realm/SwiftLint/blob/master/Rules.md#type-name)

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
      onFailure: @escaping (Error) -> Void) -> URLSessionCancellable
    {
      return _executeRequest(request, session, parser, onSuccess, onFailure)
    }

    private let _executeRequest: (
      URLRequest,
      @escaping (ModelType, Bool) -> Void,
      @escaping (NSError) -> Void) -> URLSessionCancellable

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
  let isProfile = urlValidator.isProfileUrl(urlToTest, userID: idOfUser)
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

* <a id='use-implicit-types'></a>(<a href='#use-implicit-types'>link</a>) **Don't include types where they can be easily inferred.**

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

* <a id='colon-spacing'></a>(<a href='#colon-spacing'>link</a>) **Place the colon immediately after an identifier, followed by a space.** [![SwiftLint: colon](https://img.shields.io/badge/SwiftLint-colon-007A87.svg)](https://github.com/realm/SwiftLint/blob/master/Rules.md#colon)

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

* <a id='return-arrow-spacing'></a>(<a href='#return-arrow-spacing'>link</a>) **Place a space on either side of a return arrow for readability.** [![SwiftLint: return_arrow_whitespace](https://img.shields.io/badge/SwiftLint-return__arrow__whitespace-007A87.svg)](https://github.com/realm/SwiftLint/blob/master/Rules.md#returning-whitespace)

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
  let evens = userCounts.filter { (number) in number % 2 == 0 }
  let squares = userCounts.map() { $0 * $0 }

  // RIGHT
  if userCount > 0 { ... }
  switch someValue { ... }
  let evens = userCounts.filter { number in number % 2 == 0 }
  let squares = userCounts.map { $0 * $0 }
  ```

  </details>

* <a id='unnecessary-enum-arguments'></a> (<a href='#unnecessary-enum-arguments'>link</a>) **Omit enum associated values from case statements when all arguments are unlabeled.** [![SwiftLint: empty_enum_arguments](https://img.shields.io/badge/SwiftLint-empty__enum__arguments-007A87.svg)](https://github.com/realm/SwiftLint/blob/master/Rules.md#empty-enum-arguments)

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

* <a id='favor-constructors'></a>(<a href='#favor-constructors'>link</a>) **Use constructors instead of Make() functions for NSRange and others.** [![SwiftLint: legacy_constructor](https://img.shields.io/badge/SwiftLint-legacy__constructor-007A87.svg)](https://github.com/realm/SwiftLint/blob/master/Rules.md#legacy-constructor)

  <details>

  ```swift
  // WRONG
  let range = NSMakeRange(10, 5)

  // RIGHT
  let range = NSRange(location: 10, length: 5)
  ```

  </details>

### Functions

* <a id='omit-function-void-return'></a>(<a href='#omit-function-void-return'>link</a>) **Omit `Void` return types from function definitions.** [![SwiftLint: redundant_void_return](https://img.shields.io/badge/SwiftLint-redundant__void__return-007A87.svg)](https://github.com/realm/SwiftLint/blob/master/Rules.md#redundant-void-return)

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

### Closures

* <a id='favor-void-closure-return'></a>(<a href='#favor-void-closure-return'>link</a>) **Favor `Void` return types over `()` in closure declarations.** If you must specify a `Void` return type in a function declaration, use `Void` rather than `()` to improve readability. [![SwiftLint: void_return](https://img.shields.io/badge/SwiftLint-void__return-007A87.svg)](https://github.com/realm/SwiftLint/blob/master/Rules.md#void-return)

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

* <a id='unused-closure-parameter-naming'></a>(<a href='#unused-closure-parameter-naming'>link</a>) **Name unused closure parameters as underscores (`_`).** [![SwiftLint: unused_closure_parameter](https://img.shields.io/badge/SwiftLint-unused__closure__parameter-007A87.svg)](https://github.com/realm/SwiftLint/blob/master/Rules.md#unused-closure-parameter)

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

* <a id='closure-brace-spacing'></a>(<a href='#closure-brace-spacing'>link</a>) **Single-line closures should have a space inside each brace.** [![SwiftLint: closure_spacing](https://img.shields.io/badge/SwiftLint-closure__spacing-007A87.svg)](https://github.com/realm/SwiftLint/blob/master/Rules.md#closure-spacing)

  <details>

  ```swift
  // WRONG
  let evenSquares = numbers.filter {$0 % 2 == 0}.map {  $0 * $0  }

  // RIGHT
  let evenSquares = numbers.filter { $0 % 2 == 0 }.map { $0 * $0 }
  ```

  </details>

### Operators

* <a id='infix-operator-spacing'></a>(<a href='#infix-operator-spacing'>link</a>) **Infix operators should have a single space on either side.** Prefer parenthesis to visually group statements with many operators rather than varying widths of whitespace. This rule does not apply to range operators (e.g. `1...3`) and postfix or prefix operators (e.g. `guest?` or `-1`). [![SwiftLint: operator_usage_whitespace](https://img.shields.io/badge/SwiftLint-operator__usage__whitespace-007A87.svg)](https://github.com/realm/SwiftLint/blob/master/Rules.md#operator-usage-whitespace)

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

**[⬆ back to top](#table-of-contents)**

## Patterns

* <a id='implicitly-unwrapped-optionals'></a>(<a href='#implicitly-unwrapped-optionals'>link</a>) **Prefer initializing properties at `init` time whenever possible, rather than using implicitly unwrapped optionals.**  A notable exception is UIViewController's `view` property. [![SwiftLint: implicitly_unwrapped_optional](https://img.shields.io/badge/SwiftLint-implicitly__unwrapped__optional-007A87.svg)](https://github.com/realm/SwiftLint/blob/master/Rules.md#implicitly-unwrapped-optional)

  <details>

  ```swift
  // WRONG
  class MyClass: NSObject {

    init() {
      super.init()
      someValue = 5
    }

    var someValue: Int!
  }

  // RIGHT
  class MyClass: NSObject {

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

* <a id='limit-access-control'></a>(<a href='#limit-access-control'>link</a>) **Access control should be at the strictest level possible.** Prefer `public` to `open` and `private` to `fileprivate` unless you need that behavior.

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

* <a id='private-constants'></a>(<a href='#private-constants'>link</a>) **Prefer putting constants in the top level of a file if they are `private`.** If they are `public` or `internal`, define them as static properties, for namespacing purposes.

  <details>

  ```swift
  private let privateValue = "secret"

  public class MyClass {

    public static let publicValue = "something"

    func doSomething() {
      print(privateValue)
      print(MyClass.publicValue)
    }
  }
  ```

  </details>

* <a id='namespace-using-enums'></a>(<a href='#namespace-using-enums'>link</a>) **Use caseless `enum`s for organizing `public` or `internal` constants and functions into namespaces.** Avoid creating non-namespaced global constants and functions. Feel free to nest namespaces where it adds clarity.

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

* <a id='auto-enum-values'></a>(<a href='#auto-enum-values'>link</a>) **Use Swift's automatic enum values unless they map to an external source.** Add a comment explaining why explicit values are defined. [![SwiftLint: redundant_string_enum_value](https://img.shields.io/badge/SwiftLint-redundant__string__enum__value-007A87.svg)](https://github.com/realm/SwiftLint/blob/master/Rules.md#redundant-string-enum-value)

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
  // swiftlint:disable redundant_string_enum_value
  enum UserType: String {
    case owner = "owner"
    case manager = "manager"
    case member = "member"
  }
  // swiftlint:enable redundant_string_enum_value

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

* <a id='preconditions-and-asserts'></a>(<a href='#preconditions-and-asserts'>link</a>) **Handle an unexpected but recoverable condition with an `assert` method combined with the appropriate logging in production. If the unexpected condition is not recoverable, prefer a `precondition` method or `fatalError()`.** This strikes a balance between crashing and providing insight into unexpected conditions in the wild. Only prefer `fatalError` over a `precondition` method when the failure message is dynamic, since a `precondition` method won't report the message in the crash report. [![SwiftLint: fatal_error_message](https://img.shields.io/badge/SwiftLint-fatal__error__message-007A87.svg)](https://github.com/realm/SwiftLint/blob/master/Rules.md#fatal-error-message) [![SwiftLint: force_cast](https://img.shields.io/badge/SwiftLint-force__cast-007A87.svg)](https://github.com/realm/SwiftLint/blob/master/Rules.md#force-cast) [![SwiftLint: force_try](https://img.shields.io/badge/SwiftLint-force__try-007A87.svg)](https://github.com/realm/SwiftLint/blob/master/Rules.md#force-try) [![SwiftLint: force_unwrapping](https://img.shields.io/badge/SwiftLint-force__unwrapping-007A87.svg)](https://github.com/realm/SwiftLint/blob/master/Rules.md#force-unwrapping)

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

* <a id='optional-nil-check'></a>(<a href='#optional-nil-check'>link</a>) **Check for nil rather than using optional binding if you don't need to use the value.** [![SwiftLint: unused_optional_binding](https://img.shields.io/badge/SwiftLint-unused_optional_binding-007A87.svg)](https://github.com/realm/SwiftLint/blob/master/Rules.md#unused-optional-binding)

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
  
  ```swift
  // WRONG
  protocol Foo: class {}
  
  // RIGHT
  protocol Foo: AnyObject {}
  ```
  
  </details>

**[⬆ back to top](#table-of-contents)**

## File Organization

* <a id='alphabetize-imports'></a>(<a href='#alphabetize-imports'>link</a>) **Alphabetize module imports at the top of the file a single line below the last line of the header comments. Do not add additional line breaks between import statements.** [![SwiftFormat: sortedImports](https://img.shields.io/badge/SwiftFormat-sortedImports-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/master/Rules.md#sortedImports)

  <details>

  #### Why?
  A standard organization method helps engineers more quickly determine which modules a file depends on.

  ```swift
  // WRONG

  //  Copyright © 2018 Airbnb. All rights reserved.
  //
  import DLSPrimitives
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

* <a id='limit-vertical-whitespace'></a>(<a href='#limit-vertical-whitespace'>link</a>) **Limit empty vertical whitespace to one line.** Favor the following formatting guidelines over whitespace of varying heights to divide files into logical groupings. [![SwiftLint: vertical_whitespace](https://img.shields.io/badge/SwiftLint-vertical__whitespace-007A87.svg)](https://github.com/realm/SwiftLint/blob/master/Rules.md#vertical-whitespace)

* <a id='newline-at-eof'></a>(<a href='#newline-at-eof'>link</a>) **Files should end in a newline.** [![SwiftLint: trailing_newline](https://img.shields.io/badge/SwiftLint-trailing__newline-007A87.svg)](https://github.com/realm/SwiftLint/blob/master/Rules.md#trailing-newline)

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
        forControlEvents: .TouchUpInside)
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
