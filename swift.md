# Airbnb Swift Style Guide

## Goals

Following this style guide should:

* Make it easier to read and begin understanding unfamiliar code
* Make code easier to maintain
* Reduce simple programmer errors

Note that brevity is not a primary goal. Code should be made more concise only if other good code qualities (such as readability, simplicity, and clarity) remain equal or are improved.

## Naming

* **Use camelCase for property, method, and variable names.**

```swift
var greetingText = "hello"

func displayGreetingText(greetingText: String) {
  // ...
}
```

* **Use TitleCase for type names and constants.**

```swift
class Greeter {

  // MARK: Internal
  
  static let MaxGreetings = 10
}
```

* **Underscore-prefix private property and method names.** There are several benefits to this. It gives you at-a-glance understanding of access control. It reduces the likelihood of name collisions with other arguments and local variables. Finally, it simplifies implementation of privately-modified but publicy-exposed properties.

```swift
struct MyStruct {
  var hello: String
  var world: String
}

class Foo {

  // MARK: Lifecycle

  init() {
    _myStruct = MyStruct(hello: "hello", world: "world")
  }

  // MARK: Internal

  var myStruct: MyStruct {
    return _myStruct
  }

  // MARK: Private

  private var _myStruct: MyStruct
}
```

* **Prefer putting constants in the top level of a file if they are `private`.** If they are `public` or `internal`, define them static properties, for namespacing purposes.

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

* **Avoid global functions whenever possible.** Prefer methods within type definitions.

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

* **Acronyms in names (e.g. `URL`) should be all-caps except when it’s the start of a name that would otherwise be camelCase.**

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

* **Names should be written with their most general part first and their most specific part last.** The meaning of "most general" depends on context, but should roughly mean "that which most helps you narrow down your search for the item you're looking for". Most importantly, be consistent with how you order the parts of your name.

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

* **Include a hint about type in a name if it would otherwise be ambiguous.**

```swift
// WRONG
let title: UILabel
let cancel: UIButton

// RIGHT
let titleLabel: UILabel
let cancelButton: UIButton
```

* **Event-handling functions should be named like past-tense sentences.** The subject can be omitted if it's not needed for clarity. If these are target/action handlers, use the `@objc` keyword rather than making the method internal just for the purpose of exposing it to the Objective-C runtime.

```swift
// WRONG
class MyClass {

  // MARK: Private

  private func _handleFooTap() {
    // ...
  }

  internal func _modelChanged() {
    // ...
  }
}

// RIGHT
class MyClass {

  // MARK: Private

  private func _didTapFoo() {
    // ...
  }

  @objc private func _modelDidChange() {
    // ...
  }
}
```

* **Avoid Objective-C-style acronym prefixes.** This is no longer needed to avoid naming conflicts in Swift.

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

* **Avoid `*Controller` in names of classes that aren't view controllers.** This helps reduce confusion about the purpose of a class. Consider `*Manager` instead.

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

* **Avoid naming variables or methods `description`.** This can result in conflicts with the `NSObject` property.

## Style

* **Don't include types where they can be easily inferred.** One exception is for `CGFloat`s because they don't auto-bridge with `Double` or `Int`.

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

* **Don't use `self` unless it's necessary for disambiguation or required by the language.**

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

* **Don’t include return type Void in blocks.** (Even though that’s what autocomplete does.)

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

* **Separate long function declarations with line breaks before each argument.** Also put the open curly brace on the next line so the body is indented correctly. 

```swift
class MyClass {

  // MARK: Internal

  // WRONG
  func doSomething(arg: Int, anotherArg: Int, yetAnotherArg: Int, andOneMoreArgForGoodMeasure: String) -> String {
    // This is just too long and will probably auto-wrap in a weird way
  }
  
  // WRONG
  func doSomething(arg: Int,
    anotherArg: Int,
    yetAnotherArg: Int,
    andOneMoreArgForGoodMeasure: String) -> String {
      // XCode will indent the body an extra level in
  }
  
  // RIGHT
  func doSomething(
    arg: Int,
    anotherArg: Int,
    yetAnotherArg: Int,
    andOneMoreArgForGoodMeasure: String) -> String
  {
    // Will cause correct level of indentation
  }
}  
```

* **Long function invocations should also break on each argument.** Also put the closing parenthesis on the following line. 

```swift
foo.doSomething(4, 
  anotherArg: 5,
  yetAnotherArg: 4,
  andOneMoreArgForGoodMeasure: "oaiwjeifajwe"
)
```

* **When an `if` statement becomes too long, wrap it with a new line after each of its clauses.** This includes the last clause: put the opening curly brace on a new line to ensure proper indentation of the statement body.

```swift
if
  let val1 = val1,
  let val2 = val2
  where !val2.isEmpty 
{
  print(val2)
}
```

* **Prefer immutable values whenever possible.** Use `map` and `flatMap` instead of appending to a new collection. Use `filter` instead of removing elements from a mutable collection. Mutable variables increase complexity, so try to keep them in as narrow a scope as possible. 

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

* **Avoid using optionals unless there’s a good semantic meaning.**

* **Name members of tuples for extra clarity.** Rule of thumb: if you've got more than 3 fields, you should probably be using a struct. 

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

* **Use constructors instead of *Make() functions for CGRect, CGPoint, NSRange and others.**

```swift
// WRONG
let rect = CGRectMake(10, 10, 10, 10)

// RIGHT
let rect = CGRect(x: 0, y: 0, width: 10, height: 10)
```

* **Place the colon immediately after an identifier, followed by a space.**

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

## Architecture

* **Prefer initializing properties at `init` time whenever possible, rather than using implicitly unwrapped optionals.**  A notable exception is UIViewController's `view` property.

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

* **Avoid performing any meaningful or time-intensive work in `init()`.** Avoid doing things like opening database connections, making network requests, reading large amounts of data from disk, etc. Create something like a `start()` method if these things need to be done before an object is ready for use.

* **Use functions instead of computed properties if they get to be complicated.** Also avoid didSet and willSet for the same reason.

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

* **Avoid large callback blocks - instead, organize them into methods**. This makes weak-self in blocks much simpler.

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
      self?._processResponse(response)
      completion()
    }
  }

  // MARK: Private

  func _processResponse(response) {
    // do actual processing here
  }
}
```

* **Only add guard to top of functions.** The goal of guard is to reduce branch complexity and in some ways adding guard statements in the middle of a chunk of code increases complexity.

* **Use the following rules when deciding how to set up communication between objects.**
  * Use the delegate pattern for announcing events about an object that originate at that object (e.g. a user gesture on a view, or a timer-based event.)
  * Use the callback pattern for communicating the status of some requested task (i.e. failure, progress, completion, etc.)
  * Use a multicast delegate pattern when you would use the delegate pattern but need to handle multiple listeners. Though there is no built-in Cocoa Touch mechanism for this, prefer this to KVO whenever feasible. Prefer this to NSNotificationCenter, when the event is about a particular object.
  * Use NSNotificationCenter for truly global events (note: this should be fairly uncommon.)

* **Classes should have a single, well-defined responsibility.** Keeping the number of classes down is a non-goal; don't shy away from declaring as many classes as you need.

* **If you're undecided about whether to make a set of code into a module, make it into a module.** It's easier to de-modularize code than to go the other way later.

## File Organization

* **Use `// MARK:` to separate the contents of a type definition into the sections listed below, in order.** All type definitions should be divided up in this consistent way, allowing a new reader of your code to easily jump to what he or she is interested in.
  * `// MARK: Lifecycle` for `init` and `deinit` methods.
  * `// MARK: Public` for `public` properties and methods.
  * `// MARK: Internal` for `internal` properties and methods.
  * `// MARK: Private` for `private` properties and methods.
  * If the type in question is an enum, its cases should go above the first `// MARK:`.
  * If there are typealiases, they should go above the first `// MARK:`.
  * Do not subdivide each of these sections into subsections, as it makes the method dropdown more cluttered and therefore less useful. Instead, group methods by functionality and use smart naming to make clear which methods are related. If there gets to be so many methods that sub-sections start to seem necessary, that may be a sign that your code should be refactored into multiple types.

* **Private types in a file should be marked with `// MARK: - TypeName`.** The hyphen is important here, as it visually distinguishes it from sections within the main type in the file (described above).

* **Each protocol conformance implementation should occur in dedicated type extension within the same file as the type.** This extension should be marked with `// MARK: ProtocolName`, and should contain nothing more than the methods or properties required to conform to the protocol. As a result, no `// MARK:`s are needed for defining subsections.

* **Within each top-level section, place things in the order listed below.** Again, this allows a new reader of your code to more easily find what he or she is looking for.
  * Constants (e.g. `static let Gravity: CGFloat = 9.8`)
  * Static properties (e.g. `static let sharedInstance = Foo()`)
  * Instance properties
  * Static methods
  * Class methods
  * Instance methods

* **There should always be an empty line between property declarations of different kinds.** (e.g. between static properties and instance properties.)

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

* **Computed properties and properties with property observers should appear at the end of the set of declarations of the same kind.** (e.g. instance properties.)

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

* **Example**

```swift
public class Spacefleet {
  typealias Enemy = Spacefleet

  // MARK: Lifecycle

  public init(spaceships: [Spaceship], captain: Person) {
    _spaceships = spaceships
    _captain = captain
    _changeFormation(.Launch)
  }

  // MARK: Public

  public func launch() {
    // ...
    _changeFormation(.Default)
  }

  // MARK: Internal

  func attack(enemy: Enemy) {
    _changeFormation(.Attack)
    // ...
  }

  // MARK: Private

  let _spaceships: [Spaceship]
  let _captain: Person

  private func _changeFormation(formation: Formation) {
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

## Objective-C Interoperability

* **Prefer creating pure Swift classes rather than subclassing from NSObject.** If your code needs to be used by some Objective-C code, wrap it to expose the desired functionality.
