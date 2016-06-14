# Airbnb Swift Style Guide

## Goals

Following this style guide should:

* Make it easier to read and begin understanding unfamiliar code
* Make code easier to maintain
* Reduce simple programmer errors
* Reduce cognitive load while coding

Note that brevity is not a primary goal. Code should be made more concise only if other good code qualities (such as readability, simplicity, and clarity) remain equal or are improved.

## Environment Setup

The default Xcode settings are fine, the only necessary changes are:

- Tab width: 2 spaces
- Indent width: 2 spaces

## Sections

1. [Naming](#1)
2. [Style](#2)
3. [Patterns](#3)
4. [File Organization](#4)
5. [Objective-C Interoperability](#5)

## [1](#1) <a name='1'></a> Naming

* **[1.1](#1.1) <a name='1.1'></a> Use camelCase for property, method, and variable names.**

```swift
var greetingText = "hello"

func displayGreetingText(greetingText: String) {
  // ...
}
```

* **[1.2](#1.2) <a name='1.2'></a> Use TitleCase for type names and constants.**

```swift
class Greeter {

  // MARK: Internal

  static let MaxGreetings = 10
}
```

* **[1.3](#1.3) <a name='1.3'></a> Underscore-prefix private property names only if they are mutable private properties with a similarly named internal property.** This makes it possible to mimic the behavior of the `copying` attribute of Objective-C properties. In all other cases we can rely on our file organization and access control designations to differentiate between private and public properties and methods.

```swift
class Foo {

  // MARK: Lifecycle

  init() {
    _text = NSMutableString(string: "Hello")
  }

  // MARK: Internal
  
  var text: String {
    return _text as String
  }

  // MARK: Private

  private var _text: NSMutableString
}
```

* **[1.4](#1.4) <a name='1.4'></a> Name booleans like `isSpaceship`, `hasSpacesuit`, etc.** This makes it clear that they are booleans and not other types.

* **[1.5](#1.5) <a name='1.5'></a> Acronyms in names (e.g. `URL`) should be all-caps except when it’s the start of a name that would otherwise be camelCase.**

```swift
// WRONG
class UrlValidator {

  // MARK: Internal

  func isValidUrl(URL: NSURL) -> Bool {
    // ...
  }
}

let URLValidator = UrlValidator().isValidUrl(/* some URL */)

// RIGHT
class URLValidator {

  // MARK: Internal

  func isValidURL(url: NSURL) -> Bool {
    // ...
  }
}

let urlValidator = URLValidator().isValidURL(/* some URL */)
```

* **[1.6](#1.6) <a name='1.6'></a> Names should be written with their most general part first and their most specific part last.** The meaning of "most general" depends on context, but should roughly mean "that which most helps you narrow down your search for the item you're looking for". Most importantly, be consistent with how you order the parts of your name.

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

* **[1.7](#1.7) <a name='1.7'></a> Include a hint about type in a name if it would otherwise be ambiguous.**

```swift
// WRONG
let title: String
let cancel: UIButton

// RIGHT
let titleText: String
let cancelButton: UIButton
```

* **[1.8](#1.8) <a name='1.8'></a> Event-handling functions should be named like past-tense sentences.** The subject can be omitted if it's not needed for clarity.

```swift
// WRONG
class MyClass {

  // MARK: Private

  private func handleFooButtonTap() {
    // ...
  }

  private func modelChanged() {
    // ...
  }
}

// RIGHT
class MyClass {

  // MARK: Private

  private func didTapFooButton() {
    // ...
  }

  private func modelDidChange() {
    // ...
  }
}
```

* **[1.9](#1.9) <a name='1.9'></a> Avoid Objective-C-style acronym prefixes.** This is no longer needed to avoid naming conflicts in Swift.

```swift
// WRONG
class AIRAccountManager {
  // ...
}

// RIGHT
class AccountManager {
  // ...
}
```

* **[1.10](#1.10) <a name='1.10'></a> Avoid `*Controller` in names of classes that aren't view controllers.** This helps reduce confusion about the purpose of a class. Consider `*Manager` instead.

```swift
// WRONG
class AccountController {
  // ...
}

// RIGHT
class AccountManager {
  // ...
}
```

## [2](#2) <a name='2'></a> Style

* **[2.1](#2.1) <a name='2.1'></a> Don't include types where they can be easily inferred.** One exception is for `CGFloat`s because they don't auto-bridge with `Double` or `Int`.

```swift
// WRONG
let something: MyClass = MyClass()

// RIGHT:
let something = MyClass()
```

```swift
// WRONG
let someMargin = CGFloat(5)

// RIGHT
let someMargin: CGFloat = 5
```

```swift
enum Direction {
  case Left
  case Right
}

func someDirection() -> Direction {
	// WRONG
	return Direction.Left

	// RIGHT
	return .Left
}
```

* **[2.2](#2.2) <a name='2.2'></a> Don't use `self` unless it's necessary for disambiguation or required by the language.**

```swift
class MyClass {

  // MARK: Lifecycle

  init(aProp: Int) {
	// Okay to use self here
    self.aProp = aProp
  }

  // MARK: Internal

  var aProp: Int

  func doSomething() {
    // WRONG
    self.aProp = 4

    // RIGHT
    aProp = 4

    // WRONG
    self.otherMethod()

    // RIGHT
    otherMethod()
  }
}
```

* **[2.3](#2.3) <a name='2.3'></a> Don’t include return type Void in blocks.** (Even though that’s what autocomplete does.)

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

* **[2.4](#2.4) <a name='2.4'></a> Separate long function declarations with line breaks before each argument.** If there are external parameter names, include them on the *previous* line to avoid problems with auto-indenting. Also put the open curly brace on the next line so the first executable line doesn't look like it's another parameter.

```swift
class MyClass {

  // MARK: Internal

  // WRONG
  func doSomething(arg arg1: Int, anotherArg arg2: Int, yetAnotherArg arg3: Int, andOneMoreArgForGoodMeasure arg4: String) -> String {
    // This is just too long and will probably auto-wrap in a weird way
  }

  // WRONG
  func doSomething(arg arg1: Int,
                       anotherArg arg2: Int,
                                  yetAnotherArg arg3: Int,
                                                andOneMoreArgForGoodMeasure arg4: String) -> String
  {
    // Xcode makes a staircase out of the argument list
  }
  
  // WRONG
  func doSomething(arg
    arg1: Int, anotherArg
    arg2: Int, yetAnotherArg
    arg3: Int, andOneMoreArgForGoodMeasure
    arg4: String) -> String {
    doSomethingElse() // this line blends in with the argument list
  }


  // RIGHT
  func doSomething(arg 
    arg1: Int, anotherArg
    arg2: Int, yetAnotherArg
    arg3: Int, andOneMoreArgForGoodMeasure
    arg4: String) -> String
  {
    doSomethingElse()
  }
  
  // RIGHT (example with no external arguments)
  func doSomething(
    arg: Int,
    anotherArg: Int,
    yetAnotherArg: Int,
    andOneMoreArgForGoodMeasure: String) -> String
  {
    doSomethingElse()
  }
}
```

* **[2.5](#2.5) <a name='2.5'></a> Long function invocations should also break on each argument.** Put the closing parenthesis on the last line of the invocation.

```swift
foo.doSomething(
  4,
  anotherArg: 5,
  yetAnotherArg: 4,
  andOneMoreArgForGoodMeasure: "oaiwjeifajwe")

bar.doAnotherThing(
  duck: 0,
  anotherDuck: 100,
  goose: "quack")
```

* **[2.6](#2.6) <a name='2.6'></a> When an `if` statement becomes too long, wrap it with a new line after each of its clauses.** This includes the last clause: put the opening curly brace on a new line to ensure proper indentation of the statement body.

```swift
if
  let val1 = val1,
  let val2 = val2
  where !val2.isEmpty
{
  print(val2)
}
```

* **[2.7](#2.7) <a name='2.7'></a> Name members of tuples for extra clarity.** Rule of thumb: if you've got more than 3 fields, you should probably be using a struct.

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

* **[2.8](#2.8) <a name='2.10'></a> Use constructors instead of *Make() functions for CGRect, CGPoint, NSRange and others.**

```swift
// WRONG
let rect = CGRectMake(10, 10, 10, 10)

// RIGHT
let rect = CGRect(x: 0, y: 0, width: 10, height: 10)
```

* **[2.9](#2.9) <a name='2.9'></a> Place the colon immediately after an identifier, followed by a space.**

```swift
// WRONG
var something : Int = 0

// RIGHT
var something: Int = 0
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

## [3](#3) <a name='3'></a> Patterns

* **[3.1](#3.1) <a name='3.1'></a> Prefer initializing properties at `init` time whenever possible, rather than using implicitly unwrapped optionals.**  A notable exception is UIViewController's `view` property.

```swift
// WRONG
class MyClass: NSObject {

  // MARK: Lifecycle

  init() {
    super.init()
    someValue = 5
  }

  // MARK: Internal

  var someValue: Int!
}

// RIGHT
class MyClass: NSObject {

  // MARK: Lifecycle

  init() {
    someValue = 0
    super.init()
  }

  // MARK: Internal

  var someValue: Int
}
```

* **[3.2](#3.2) <a name='3.2'></a> Avoid performing any meaningful or time-intensive work in `init()`.** Avoid doing things like opening database connections, making network requests, reading large amounts of data from disk, etc. Create something like a `start()` method if these things need to be done before an object is ready for use.

* **[3.3](#3.3) <a name='3.3'></a> Use functions instead of computed properties if they get to be complicated.** Also avoid didSet and willSet for the same reason.

```swift
// WRONG
// Less readable
class MyClass {

  // MARK: Internal

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

  // MARK: Internal

  func someValue() -> Int {
  }

  func setSomeValue(newValue: Int) {
  }
}
```

* **[3.4](#3.4) <a name='3.4'></a> Avoid large callback blocks - instead, organize them into methods**. This makes weak-self in blocks much simpler.

```swift
//WRONG
class MyClass {

  // MARK: Internal

  func doRequest(completion: () -> Void) {
    API.request() { [weak self] response in
      if let sSelf = self {
        // lots of processing and side effects and whatever
      }
      completion()
    }
  }
}

// RIGHT
class MyClass {

  // MARK: Internal

  func doRequest(completion: () -> Void) {
    API.request() { [weak self] response in
      self?.processResponse(response)
      completion()
    }
  }

  // MARK: Private

  func processResponse(response) {
    // do actual processing here
  }
}
```

* **[3.5](#3.5) <a name='3.5'></a> Only add guard to top of functions.** The goal of guard is to reduce branch complexity and in some ways adding guard statements in the middle of a chunk of code increases complexity.

* **[3.6](#3.6) <a name='3.6'></a> Use the following rules when deciding how to set up communication between objects.**
  * Use the delegate pattern for announcing events about an object that originate at that object (e.g. a user gesture on a view, or a timer-based event.)
  * Use the callback pattern for communicating the status of some requested task (i.e. failure, progress, completion, etc.)
  * Use a multicast delegate pattern when you would use the delegate pattern but need to handle multiple listeners. Though there is no built-in Cocoa Touch mechanism for this, prefer this to KVO whenever feasible. Prefer this to NSNotificationCenter, when the event is about a particular object.
  * Use NSNotificationCenter for truly global events (note: this should be fairly uncommon.)

* **[3.7](#3.7) <a name='3.7'></a> Classes should have a single, well-defined responsibility.** Keeping the number of classes down is a non-goal; don't shy away from declaring as many classes as you need.

* **[3.8](#3.8) <a name='3.8'></a> If you're undecided about whether to make a set of code into a module, make it into a module.** It's easier to de-modularize code than to go the other way later.

* **[3.9](#3.9) <a name='3.9'></a> Avoid global functions whenever possible.** Prefer methods within type definitions.

```swift
// WRONG
func jump(person: Person) {
  // ...
}

func personAgeStringFromTimeInterval(timeInterval: NSTimeInterval) {
  // ...
}

// RIGHT
class Person {

  // MARK: Internal

  static func ageStringFromTimeInterval(timeInterval: NSTimeInterval) {
    // ...
  }

  func jump() {
    // ...
  }
}
```

* **[3.10](#3.10) <a name='3.10'></a> Prefer putting constants in the top level of a file if they are `private`.** If they are `public` or `internal`, define them as static properties, for namespacing purposes.

```swift
private let PrivateValue = "secret"

class MyClass {

  // MARK: Public

  public static let PublicValue = "something"

  // MARK: Internal

  func doSomething() {
    print(PrivateValue)
    print(MyClass.PublicValue)
  }
}
```

* **[3.11](#3.11) <a name='3.11'></a> Avoid using optionals unless there’s a good semantic meaning.**

* **[3.12](#3.12) <a name='3.12'></a> Prefer immutable values whenever possible.** Use `map` and `flatMap` instead of appending to a new collection. Use `filter` instead of removing elements from a mutable collection. Mutable variables increase complexity, so try to keep them in as narrow a scope as possible.

```swift
// WRONG
func computeResults(input: [String]) -> [SomeType] {
  var results = [SomeType]()
  for element in input {
    let result = transform(element)
    results.append(result)
  }
  return results
}

// RIGHT
func computeResults(input: [String]) -> [SomeType] {
  return input.map(transform)
}

func computeMoreResults(input: [String]) -> [SomeType] {
  return input.map { $0.something }
}
```

```swift
// WRONG
func computeResults(input: [String]) -> [SomeType] {
  var results = [SomeType]()
  for element in input {
    if let result = transformThatReturnsAnOptional(element) {
      results.append(result)
    }
  }
  return results
}

// RIGHT
func computeResults(input: [String]) -> [SomeType] {
  return input.flatMap(transformThatReturnsAnOptional)
}
```

```swift
// WRONG
func updateDisplayedData() {
  var data = dataSource.getData()

  // Apply first transformation to data
  for key in data.keys {
    data[key] = massageValue(data[key])
  }

  // Apply second transformation to data
  for key in data.keys {
    data[key] = manipulateValue(data[key])
  }

  // Display transformed data
  display(someHash)
}

// RIGHT
func updateDisplayedData() {
  let data = dataSource.getData()
  let massagedData = massageData(data)
  let manipulatedData = manipulateData(massagedData)
  display(manipulatedData)
}
```

* **[3.13](#3.13) <a name='3.13'></a> Handle an unexpected condition with a `precondition` method when you cannot reasonably recover from it. Otherwise, use an `assert` method combined with appropriate logging in production.** This strikes a balance between crashing and providing insight into unexpected conditions in the wild. There is little reason to prefer the `fatalError` methods over the `precondition` methods, as we should not be building with the `-Ounchecked` optimization level.

```swift
func transformItem(atIndex index: Int, ofArray array: [Item]) -> Item {
  precondition(index >= 0 && index < array.count)
  // It's impossible to continue executing if the precondition has failed.
  // ...
}

func didSubmit(text text: String) {
  // It's unclear how this was called with an empty string; our custom text field shouldn't allow this.
  // This assert is useful for debugging but it's OK if we simply ignore this scenario in production.
  guard (text.characters.count > 0) else {
    let message = "Unexpected empty string"
    log(message)
    assertionFailure(message)
    return
  }
  // ...
}
```

## [4](#4) <a name='4'></a> File Organization

* **[4.1](#4.1) <a name='4.1'></a> Use `// MARK:` to separate the contents of a type definition into the sections listed below, in order.** All type definitions should be divided up in this consistent way, allowing a new reader of your code to easily jump to what he or she is interested in.
  * `// MARK: Lifecycle` for `init` and `deinit` methods.
  * `// MARK: Public` for `public` properties and methods.
  * `// MARK: Internal` for `internal` properties and methods.
  * `// MARK: Private` for `private` properties and methods.
  * If the type in question is an enum, its cases should go above the first `// MARK:`.
  * If there are typealiases, they should go above the first `// MARK:`.
  * Do not subdivide each of these sections into subsections, as it makes the method dropdown more cluttered and therefore less useful. Instead, group methods by functionality and use smart naming to make clear which methods are related. If there gets to be so many methods that sub-sections start to seem necessary, that may be a sign that your code should be refactored into multiple types.
  * If the type in question is a simple value type, it is OK to omit the `// MARK:`s, as it would hurt legibility.

* **[4.2](#4.2) <a name='4.2'></a> Private types in a file should be marked with `// MARK: - TypeName`.** The hyphen is important here, as it visually distinguishes it from sections within the main type in the file (described above).

* **[4.3](#4.3) <a name='4.3'></a> Each protocol conformance implementation should occur in dedicated type extension within the same file as the type.** This extension should be marked with `// MARK: ProtocolName`, and should contain nothing more than the methods or properties required to conform to the protocol. As a result, no `// MARK:`s are needed for defining subsections.

* **[4.4](#4.4) <a name='4.4'></a> Within each top-level section, place things in the order listed below.** Again, this allows a new reader of your code to more easily find what he or she is looking for.
  * Constants (e.g. `static let Gravity: CGFloat = 9.8`)
  * Static properties (e.g. `static let sharedInstance = Foo()`)
  * Instance properties
  * Static methods
  * Class methods
  * Instance methods

* **[4.5](#4.5) <a name='4.5'></a> There should always be an empty line between property declarations of different kinds.** (e.g. between static properties and instance properties.)

```swift
// WRONG
static let GravityEarth: CGFloat = 9.8
static let GravityMoon: CGFloat = 1.6
var gravity: CGFloat

// RIGHT
static let GravityEarth: CGFloat = 9.8
static let GravityMoon: CGFloat = 1.6

var gravity: CGFloat
```

* **[4.6](#4.6) <a name='4.6'></a> Computed properties and properties with property observers should appear at the end of the set of declarations of the same kind.** (e.g. instance properties.)

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

* **[4.7](#4.7) <a name='4.7'></a> Example**

```swift
public class Spacefleet {
  typealias Enemy = Spacefleet

  // MARK: Lifecycle

  public init(spaceships: [Spaceship], captain: Person) {
    self.spaceships = spaceships
    self.captain = captain
    changeFormation(.Launch)
  }

  // MARK: Public

  public func launch() {
    // ...
    changeFormation(.Default)
  }

  // MARK: Internal

  func attack(enemy: Enemy) {
    changeFormation(.Attack)
    // ...
  }

  // MARK: Private

  let spaceships: [Spaceship]
  let captain: Person

  private func changeFormation(formation: Formation) {
    // ...
  }
}

// MARK: SpaceshipDelegate

extension Spacefleet: SpaceshipDelegate {

  func spaceship(spaceship: Spaceship, shieldLevelDidChange shieldLevel: CGFloat) {
    // ...
  }

  func spaceship(spaceship: Spaceship, fuelLevelDidChange fuelLevel: CGFloat) {
    // ...
  }
}

// MARK: - Formation

private enum Formation {
  case Launch
  case Default
  case Attack
}
```

* **[4.8](#4.8) <a name='4.8'></a> Files should end in a newline**

## [5](#5) <a name='5'></a> Objective-C Interoperability

* **[5.1](#5.1) <a name='5.1'></a> Prefer creating pure Swift classes rather than subclassing from NSObject.** If your code needs to be used by some Objective-C code, wrap it to expose the desired functionality.

* **[5.2](#5.2) <a name='5.2'></a>Target-action handlers should use the `dynamic` keyword.** Do not make a method `internal` just for the purpose of exposing it to the Objective-C runtime.

```swift
class MyClass {

  // MARK: Private

  let fooButton = UIButton()

  private func setUpFooButton() {
    fooButton.addTarget(self,
      action: "didTapFooButton",
      forControlEvents: .TouchUpInside)
  }

  // WRONG
  func didTapFooButton() {
    // ...
  }

  // RIGHT
  dynamic private func didTapFooButton() {
    // ...
  }
}
```
