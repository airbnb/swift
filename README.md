# Airbnb Swift Style Guide

## Goals

Following this style guide should:

* Make it easier to read and begin understanding unfamiliar code.
* Make code easier to maintain.
* Reduce simple programmer errors.
* Reduce cognitive load while coding.

Note that brevity is not a primary goal. Code should be made more concise only if other good code qualities (such as readability, simplicity, and clarity) remain equal or are improved.

## Guiding Tenets

* This guide is in addition to the official [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/). These rules should not contradict that document.
* These rules should not fight Xcode's <kbd>^</kbd> + <kbd>I</kbd> indentation behavior.

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
  
* <a id='trailing-whitespace'></a>(<a href='#trailing-whitespace'>link</a>) **Trim trailing whitespace in all lines.**

**[⬆ back to top](#table-of-contents)**

## Naming

* <a id='use-camel-case'></a>(<a href='#use-camel-case'>link</a>) **Use UpperCamelCase for type and protocol names, and lowerCamelCase for everything else.** SwiftLint: [`type_name`](https://github.com/realm/SwiftLint/blob/master/Rules.md#type-name)

  <details>

  ```swift
  protocol SpaceThing {
    // ...
  }

  class Spacefleet: SpaceThing {

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

  let myFleet = Spacefleet()
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

    func isUrlReachable(_ URL: URL) -> Bool {
      // ...
    }
  }

  let URLValidator = UrlValidator().isValidUrl(/* some URL */)

  // RIGHT
  class URLValidator {

    func isValidURL(_ url: URL) -> Bool {
      // ...
    }

    func isURLReachable(_ url: URL) -> Bool {
      // ...
    }
  }

  let urlValidator = URLValidator().isValidURL(/* some URL */)
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

* <a id='omit-self'></a>(<a href='#omit-self'>link</a>) **Don't use `self` unless it's necessary for disambiguation or required by the language.**

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

* <a id='long-function-declaration'></a>(<a href='#long-function-declaration'>link</a>) **Separate [long](#column-width) function declarations with line breaks before each argument label.** Put the open curly brace on the next line so the first executable line doesn't look like it's another parameter. SwiftLint: [`multiline_parameters`](https://github.com/realm/SwiftLint/blob/master/Rules.md#multiline-parameters), [`vertical_parameter_alignment_on_call`](https://github.com/realm/SwiftLint/blob/master/Rules.md#vertical-parameter-alignment-on-call)

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

    // RIGHT
    func generateStars(
      at location: Point,
      count: Int,
      color: StarColor,
      withAverageDistance averageDistance: Float) -> String
    {
      populateUniverse()
    }
  }
  ```

  </details>

 * <a id='long-function-declaration-return-line'></a>(<a href='#long-function-declaration-return-line'>link</a>) **Separate the last [long](#column-width) line of a function declaration or definition by putting a line break before the return type.** The line break should be after the closing parenthesis of the function signature and before the return arrow.

  <details>

  ```swift
  class Universe {

    // WRONG
    func generateStars(
      at location: Point,
      count: Int,
      color: StarColor,
      withAverageDistance averageDistance: Float,
      delegateWrapper: WeakVariableWrapper<ConstellationSearchResultsContentPresenterDelegate>) -> EpoxyableModel
    {
      // The last line is too long and will probably auto-wrap in a weird way
      populateUniverse()
    }

    // RIGHT
    func generateStars(
      at location: Point,
      count: Int,
      color: StarColor,
      withAverageDistance averageDistance: Float,
      delegateWrapper: WeakVariableWrapper<ConstellationSearchResultsContentPresenterDelegate>) 
      -> EpoxyableModel
    {
      populateUniverse()
    }
  }
  ```

  </details>

* <a id='long-function-invocation'></a>(<a href='#long-function-invocation'>link</a>) **[Long](#column-width) function invocations should also break on each argument.** Put the closing parenthesis on the last line of the invocation. SwiftLint: [`multiline_arguments`](https://github.com/realm/SwiftLint/blob/master/Rules.md#multiline-arguments) [`vertical_parameter_alignment_on_call`](https://github.com/realm/SwiftLint/blob/master/Rules.md#vertical-parameter-alignment-on-call)

  <details>

  ```swift
  universe.generateStars(
    at: location,
    count: 5,
    color: starColor,
    withAverageDistance: 4)

  universe.generate(
    5,
    .stars,
    at: location)
  ```

  </details>

* <a id='multi-line-array'></a>(<a href='#multi-line-array'>link</a>) **Multi-line arrays should have each bracket on a separate line.** Put the opening and closing brackets on separate lines from any of the elements of the array. Also add a trailing comma on the last element.

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

  </details>

* <a id='long-if-statement'></a>(<a href='#long-if-statement'>link</a>) **When an `if`/`guard` statement becomes [too long](#column-width), start each condition with a newline, including the first.** This includes the last clause: put the opening curly brace on a new line to ensure proper indentation of the statement body. The first condition is also indented to vertically align all conditions.

  <details>

  ```swift
  if
    let val1 = val1,
    let val2 = val2,
    !val2.isEmpty
  {
    print(val2)
  }

  guard
    let value = some,
    let value2 = someOther else
  {
    return
  }
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

* <a id='favor-constructors'></a>(<a href='#favor-constructors'>link</a>) **Use constructors instead of Make() functions for CGRect, CGPoint, NSRange and others.** SwiftLint: [`legacy_constructor`](https://github.com/realm/SwiftLint/blob/master/Rules.md#legacy-constructor)

  <details>

  ```swift
  // WRONG
  let rect = CGRectMake(10, 10, 10, 10)

  // RIGHT
  let rect = CGRect(x: 0, y: 0, width: 10, height: 10)
  ```

  </details>

* <a id='use-modern-swift-extensions'></a>(<a href='#use-modern-swift-extensions'>link</a>) **Favor modern Swift extension methods over older Objective-C global methods.** SwiftLint: [`legacy_cggeometry_functions`](https://github.com/realm/SwiftLint/blob/master/Rules.md#legacy-cggeometry-functions), [`legacy_constant`](https://github.com/realm/SwiftLint/blob/master/Rules.md#legacy-constant), [`legacy_nsgeometry_functions`](https://github.com/realm/SwiftLint/blob/master/Rules.md#legacy-nsgeometry-functions)

  <details>

  ```swift
  // WRONG
  var rect = CGRectZero
  var width = CGRectGetWidth(rect)

  // RIGHT
  var rect = CGRect.zero
  var width = rect.width
  ```

  </details>

* <a id='colon-spacing'></a>(<a href='#colon-spacing'>link</a>) **Place the colon immediately after an identifier, followed by a space.** SwiftLint: [`colon`](https://github.com/realm/SwiftLint/blob/master/Rules.md#colon)

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

* <a id='return-arrow-spacing'></a>(<a href='#return-arrow-spacing'>link</a>) **Place a space on either side of a return arrow for readability.** SwiftLint: [`return_arrow_whitespace`](https://github.com/realm/SwiftLint/blob/master/Rules.md#returning-whitespace)

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

* <a id='unnecessary-parens'></a>(<a href='#unnecessary-parens'>link</a>) **Omit unnecessary parentheses.** SwiftLint: [`control_statement`](https://github.com/realm/SwiftLint/blob/master/Rules.md#control-statement), [`empty_parentheses_with_trailing_closure`](https://github.com/realm/SwiftLint/blob/master/Rules.md#empty-parentheses-with-trailing-closure), [`unneeded_parentheses_in_closure_argument`](https://github.com/realm/SwiftLint/blob/master/Rules.md#unneeded-parentheses-in-closure-argument),

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

* <a id='unnecessary-enum-arguments'></a> (<a href='#unnecessary-enum-arguments'>link</a>) **Omit enum associated values from case statements when all arguments are unlabeled.** SwiftLint: [`empty_enum_arguments`](https://github.com/realm/SwiftLint/blob/master/Rules.md#empty-enum-arguments)

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

* <a id='attributes-on-prev-line'></a>(<a href='#attributes-on-prev-line'>link</a>) **Place function/type attributes on the line above the declaration**.

  <details>

  ```swift
  // WRONG
  @objc class Spaceship: NSObject {
    @discardableResult func fly() {
    }
  }

  // RIGHT

  @objc
  class Spaceship: NSObject {
    @discardableResult
    func fly() {
    }
  }
  ```

  </details>

### Functions

* <a id='omit-function-void-return'></a>(<a href='#omit-function-void-return'>link</a>) **Omit `Void` return types from function definitions.** SwiftLint: [`redundant_void_return`](https://github.com/realm/SwiftLint/blob/master/Rules.md#redundant-void-return)

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

* <a id='long-function-chains'></a>(<a href='#long-function-chains'>link</a>) **Separate [long](#column-width) function chains with line breaks before each dot.** SwiftLint: [`multiline_function_chains`](https://github.com/realm/SwiftLint/blob/master/Rules.md#multiline-function-chains)

  <details>

  #### Why?
  It's easier to follow control flow through long function chains when each call has the same indentation.

  ```swift
  /// WRONG

  match(pattern: pattern).compactMap { range in
      return Command(string: contents, range: range)
    }.compactMap { command in
      return command.expand()
  }

  /// RIGHT

  match(pattern: pattern)
    .compactMap { range in
      return Command(string: contents, range: range)
    }
    .compactMap { command in
      return command.expand()
  }

  // Short function chains can still be on one line:
  let evenSquares = [20, 17, 35, 4].filter { $0 % 2 == 0 }.map { $0 * $0 }
  ```

  </details>

### Closures

* <a id='omit-closure-void-return'></a>(<a href='#omit-closure-void-return'>link</a>) **Omit `Void` return types from closure definitions.** (Even though that’s what autocomplete does.)

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

  </details>

* <a id='favor-void-closure-return'></a>(<a href='#favor-void-closure-return'>link</a>) **Favor `Void` return types over `()` in closure declarations.** If you must specify a `Void` return type in a function declaration, use `Void` rather than `()` to improve readability. SwiftLint: [`void_return`](https://github.com/realm/SwiftLint/blob/master/Rules.md#void-return)

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

* <a id='omit-closure-parameters-unnecessary-types'></a>(<a href='#omit-closure-parameters-unnecessary-types'>link</a>) **Omit unnecessary type specifiers for closure parameters.**

  <details>

  ```swift
  // WRONG
  someAsyncThing() { (argument: Bool, argument2: Bool) -> Void in
    ...
  }

  // RIGHT
  someAsyncThing() { argument, argument2 in
    ...
  }
  ```

  </details>

* <a id='unused-closure-parameter-naming'></a>(<a href='#unused-closure-parameter-naming'>link</a>) **Name unused closure parameters as underscores (`_`).** SwiftLint: [`unused_closure_parameter`](https://github.com/realm/SwiftLint/blob/master/Rules.md#unused-closure-parameter)

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

* <a id='closure-end-brace-indentation'></a>(<a href='#closure-end-brace-indentation'>link</a>) **Closure end braces should have the same indentation as the line with their opening brace.** This makes it easier to follow control flow through closures. SwiftLint: [`closure_end_indentation`](https://github.com/realm/SwiftLint/blob/master/Rules.md#closure-end-indentation)

  <details>

  ```swift
  // WRONG

  match(pattern: pattern)
    .compactMap { range in
      return Command(string: contents, range: range)
  }
    .compactMap { command in
      return command.expand()
  }

  values.forEach { value in
    print(value)
    }

  // RIGHT

  match(pattern: pattern)
    .compactMap { range in
      return Command(string: contents, range: range)
    }
    .compactMap { command in
      return command.expand()
    }

  values.forEach { value in
    print(value)
  }
  ```

  </details>

* <a id='closure-brace-spacing'></a>(<a href='#closure-brace-spacing'>link</a>) **Single-line closures should have a space inside each brace.** SwiftLint: [`closure_spacing`](https://github.com/realm/SwiftLint/blob/master/Rules.md#closure-spacing)

  <details>

  ```swift
  // WRONG
  let evenSquares = numbers.filter {$0 % 2 == 0}.map {  $0 * $0  }

  // RIGHT
  let evenSquares = numbers.filter { $0 % 2 == 0 }.map { $0 * $0 }
  ```

  </details>

### Operators

* <a id='infix-operator-spacing'></a>(<a href='#infix-operator-spacing'>link</a>) **Infix operators should have a single space on either side.** Prefer parenthesis to visually group statements with many operators rather than varying widths of whitespace. This rule does not apply to range operators (e.g. `1...3`) and postfix or prefix operators (e.g. `guest?` or `-1`). SwiftLint: [`operator_usage_whitespace`](https://github.com/realm/SwiftLint/blob/master/Rules.md#operator-usage-whitespace)

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

* <a id='implicitly-unwrapped-optionals'></a>(<a href='#implicitly-unwrapped-optionals'>link</a>) **Prefer initializing properties at `init` time whenever possible, rather than using implicitly unwrapped optionals.**  A notable exception is UIViewController's `view` property. SwiftLint: [`implicitly_unwrapped_optional`](https://github.com/realm/SwiftLint/blob/master/Rules.md#implicitly-unwrapped-optional)

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

* <a id='complex-property-accessor'></a>(<a href='#complex-property-accessor'>link</a>) **Use functions instead of computed properties if they get to be complicated.**

  <details>

  ```swift
  class SomeClass {
    // WRONG
    // Too complicated, too many side effects
    var someThing: String {
      if let someProperty = someProperty {
        someOtherProperty = doSomething(with: someProperty)
        doSomethingElse()
      } else {
        someOtherProperty = doSomethingDifferent()
      }

      return someOtherProperty
    }

    // RIGHT
    // Simple, no side effects
    var someThing2: String {
      return "\(theFirstThing) \(theSecondThing)"
    }
  }
  ```
  </details>

* Also avoid `didSet` and `willSet` for the same reason.

  <details>

  ```swift
  // WRONG
  // Less readable
  class MyClass {

    var someValue: Int {
      get {
        // return something computed
      }
      set(newValue) {
        // set a bunch of other values
      }
    }
  }

  // RIGHT
  // More readable and clearer that there are side effects or nontrivial computation
  class MyClass {

    func someValue() -> Int {
    }

    func setSomeValue(newValue: Int) {
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
        if let strongSelf = self {
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
        guard let strongSelf = self else { return }
        strongSelf.doSomething(strongSelf.property)
        completion()
      }
    }

    func doSomething(nonOptionalParameter: SomeClass) {
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

* <a id='preconditions-and-asserts'></a>(<a href='#preconditions-and-asserts'>link</a>) **Handle an unexpected but recoverable condition with an `assert` method combined with the appropriate logging in production. If the unexpected condition is not recoverable, prefer a `precondition` method or `fatalError()`.** This strikes a balance between crashing and providing insight into unexpected conditions in the wild. Only prefer `fatalError` over a `precondition` method when the failure message is dynamic, since a `precondition` method won't report the message in the crash report. SwiftLint: [`fatal_error_message`](https://github.com/realm/SwiftLint/blob/master/Rules.md#fatal-error-message), [`force_cast`](https://github.com/realm/SwiftLint/blob/master/Rules.md#force-cast), [`force_try`](https://github.com/realm/SwiftLint/blob/master/Rules.md#force-try), [`force_unwrapping`](https://github.com/realm/SwiftLint/blob/master/Rules.md#force-unwrapping)

  <details>

  ```swift
  func didSubmitText(_ text: String) {
    // It's unclear how this was called with an empty string; our custom text field shouldn't allow this.
    // This assert is useful for debugging but it's OK if we simply ignore this scenario in production.
    guard text.isEmpty else {
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

* <a id='switch-with-where'></a>(<a href='#switch-with-where'>link</a>) **Be careful when using `where` clauses when handling multiple cases in a `switch`.**

  <details>

  #### Why?
  The where clause only applies to the last case in line.

  ```swift
  // WRONG
  func doThing() {
    switch anEnum {
    //where x == y will only be evaluated if anEnum is .B
    case .a, .b where x == y:
      doDifferentThing()
    }
  }

  // RIGHT
  func doThing() {
    switch anEnum {
    case .a where x == y,
         .b where x == y:
      doDifferentThing()
    }
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

* <a id='optional-nil-check'></a>(<a href='#optional-nil-check'>link</a>) **Check for nil rather than using optional binding if you don't need to use the value.**

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

**[⬆ back to top](#table-of-contents)**

## File Organization

* <a id='alphabetize-imports'></a>(<a href='#alphabetize-imports'>link</a>) **Alphabetize module imports at the top of the file a single line below the last line of the header comments. Do not add additional line breaks between import statements.**

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

* <a id='limit-vertical-whitespace'></a>(<a href='#limit-vertical-whitespace'>link</a>) **Limit empty vertical whitespace to one line.** Favor the following formatting guidelines over whitespace of varying heights to divide files into logical groupings. SwiftLint: [`vertical_whitespace`](https://github.com/realm/SwiftLint/blob/master/Rules.md#vertical-whitespace)

* <a id='marks-for-types'></a>(<a href='#marks-for-types'>link</a>) **Each type in a file should be preceded by `// MARK: - TypeName`.** SwiftLint: [`mark`](https://github.com/realm/SwiftLint/blob/master/Rules.md#mark)

  <details>

  #### Why?
  The hyphen visually distinguishes types from sections within those types (described below).

  </details>

* <a id='marks-within-types'></a>(<a href='#marks-within-types'>link</a>) **Use `// MARK:` to separate the contents of a type definition into the sections listed below, in order.** All type definitions should be divided up in this consistent way, allowing a new reader of your code to easily jump to what he or she is interested in. SwiftLint: [`mark`](https://github.com/realm/SwiftLint/blob/master/Rules.md#mark)
  * `// MARK: Lifecycle` for `init` and `deinit` methods.
  * `// MARK: Open` for `open` properties and methods.
  * `// MARK: Public` for `public` properties and methods.
  * `// MARK: Internal` for `internal` properties and methods.
  * `// MARK: Fileprivate` for `fileprivate` properties and methods.
  * `// MARK: Private` for `private` properties and methods.
  * If the type in question is an enum, its cases should go above the first `// MARK:`.
  * If there are typealiases, they should go above the first `// MARK:`.
  * Do not subdivide each of these sections into subsections, as it makes the method dropdown more cluttered and therefore less useful. Instead, group methods by functionality and use smart naming to make clear which methods are related. If there are enough methods that sub-sections seem necessary, consider refactoring your code into multiple types.
  * If the type in question is a simple value type, it is OK to omit the `// MARK:`s, as it would hurt legibility.

* <a id='extensions-for-protocol-conformance'></a>(<a href='#extensions-for-protocol-conformance'>link</a>)
 **Each protocol conformance implementation should occur in dedicated type extension within the same file as the type.** This extension should be marked with `// MARK: ProtocolName`, and should contain nothing more than the methods or properties required to conform to the protocol. As a result, no `// MARK:`s are needed for defining subsections.

* <a id='subsection-organization'></a>(<a href='#subsection-organization'>link</a>) **Within each top-level section, place content in the following order.** This allows a new reader of your code to more easily find what he or she is looking for.
  * Constants (e.g. `static let gravity: CGFloat = 9.8`)
  * Static properties (e.g. `static let sharedInstance = Account()`)
  * Instance properties
  * Static methods
  * Class methods
  * Instance methods

* <a id='newline-between-subsections'></a>(<a href='#newline-between-subsections'>link</a>) **Add empty lines between property declarations of different kinds.** (e.g. between static properties and instance properties.)

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

* <a id='computed-properties-at-end'></a>(<a href='#computed-properties-at-end'>link</a>) **Computed properties and properties with property observers should appear at the end of the set of declarations of the same kind.** (e.g. instance properties.)

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

* <a id='newline-at-eof'></a>(<a href='#newline-at-eof'>link</a>) **Files should end in a newline.** SwiftLint: [`trailing_newline`](https://github.com/realm/SwiftLint/blob/master/Rules.md#trailing-newline)

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
