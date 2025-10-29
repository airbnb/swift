# Airbnb Swift Style Guide

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fairbnb%2Fswift%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/airbnb/swift)

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
  * If a rule changes the format of the code, it needs to be able to be reformatted automatically (either using [SwiftFormat](https://github.com/nicklockwood/SwiftFormat) or [SwiftLint](https://github.com/realm/SwiftLint) autocorrect).
  * For rules that don't directly change the format of the code, we should have a lint rule that throws a warning.
  * Exceptions to these rules should be rare and heavily justified.

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
1. [Testing](#testing)
1. [Contributors](#contributors)
1. [Amendments](#amendments)

## Xcode Formatting

_You can enable the following settings in Xcode by running [this script](resources/xcode_settings.bash), e.g. as part of a "Run Script" build phase._

* <a id='column-width'></a>(<a href='#column-width'>link</a>) **Each line should have a maximum column width of 100 characters.** [![SwiftFormat: wrap](https://img.shields.io/badge/SwiftFormat-wrap-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#wrap)

  <details>

  #### Why?
  Due to larger screen sizes, we have opted to choose a page guide greater than 80.

  We currently only "strictly enforce" (lint / auto-format) a maximum column width of 130 characters to limit the cases where manual clean up is required for reformatted lines that fall slightly above the threshold.

  </details>

* <a id='spaces-over-tabs'></a>(<a href='#spaces-over-tabs'>link</a>) **Use 2 spaces to indent lines.** [![SwiftFormat: indent](https://img.shields.io/badge/SwiftFormat-indent-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#indent)

* <a id='trailing-whitespace'></a>(<a href='#trailing-whitespace'>link</a>) **Trim trailing whitespace in all lines.** [![SwiftFormat: trailingSpace](https://img.shields.io/badge/SwiftFormat-trailingSpace-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#trailingSpace)

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

  _Exception: You may prefix a private property with an underscore if it is backing an identically-named property or method with a higher access level._

  <details>

  #### Why?
  There are specific scenarios where a backing property or method that is prefixed with an underscore could be easier to read than using a more descriptive name.

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
      onFailure: @escaping (Error) -> Void
    ) -> URLSessionCancellable {
      return _executeRequest(request, onSuccess, onFailure)
    }

    private let _executeRequest: (
      URLRequest,
      @escaping (ModelType, Bool) -> Void,
      @escaping (Error) -> Void
    ) -> URLSessionCancellable
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

* <a id='use-implicit-types'></a>(<a href='#use-implicit-types'>link</a>) **Don't include types where they can be easily inferred.** [![SwiftFormat: redundantType](https://img.shields.io/badge/SwiftFormat-redundantType-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#redundantType)

  <details>

  ```swift
  // WRONG
  let sun: Star = Star(mass: 1.989e30)
  let earth: Planet = Planet.earth

  // RIGHT
  let sun = Star(mass: 1.989e30)
  let earth = Planet.earth

  // NOT RECOMMENDED. However, since the linter doesn't have full type information, this is not enforced automatically.
  let moon: Moon = earth.moon // returns `Moon`

  // RIGHT
  let moon = earth.moon
  let moon: PlanetaryBody? = earth.moon

  // WRONG: Most literals provide a default type that can be inferred.
  let enableGravity: Bool = true
  let numberOfPlanets: Int = 8
  let sunMass: Double = 1.989e30

  // RIGHT
  let enableGravity = true
  let numberOfPlanets = 8
  let sunMass = 1.989e30
  
  // WRONG: Types can be inferred from if/switch expressions as well if each branch has the same explicit type.
  let smallestPlanet: Planet =
    if treatPlutoAsPlanet {
      Planet.pluto
    } else {
      Planet.mercury
    }

  // RIGHT
  let smallestPlanet =
    if treatPlutoAsPlanet {
      Planet.pluto
    } else {
      Planet.mercury
    }
  ```

  </details>

* <a id='infer-property-types'></a>(<a href='#infer-property-types'>link</a>) **Prefer letting the type of a variable or property be inferred from the right-hand-side value rather than writing the type explicitly on the left-hand side.** [![SwiftFormat: propertyTypes](https://img.shields.io/badge/SwiftFormat-propertyTypes-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#propertyTypes)

  <details>

  Prefer using inferred types when the right-hand-side value is a static member with a leading dot (e.g. an `init`, a `static` property / function, or an enum case). This applies to both local variables and property declarations:

  ```swift
  // WRONG
  struct SolarSystemBuilder {
    let sun: Star = .init(mass: 1.989e30)
    let earth: Planet = .earth

    func setUp() {
      let galaxy: Galaxy = .andromeda
      let system: SolarSystem = .init(sun, earth)
      galaxy.add(system)
    }
  }
  
  // RIGHT
  struct SolarSystemBuilder {
    let sun = Star(mass: 1.989e30)
    let earth = Planet.earth

    func setUp() {
      let galaxy = Galaxy.andromeda
      let system = SolarSystem(sun, earth)
      galaxy.add(system)
    }
  }
  ```

  Explicit types are still permitted in other cases:

  ```swift
  // RIGHT: There is no right-hand-side value, so an explicit type is required.
  let sun: Star

  // RIGHT: The right-hand-side is not a static member of the left-hand type.
  let moon: PlantaryBody = earth.moon
  let sunMass: Float = 1.989e30
  let planets: [Planet] = []
  let venusMoon: Moon? = nil
  ```

  There are some rare cases where the inferred type syntax has a different meaning than the explicit type syntax. In these cases, the explicit type syntax is still permitted:

  ```swift
  extension String {
    static let earth = "Earth"
  }

  // WRONG: fails with "error: type 'String?' has no member 'earth'"
  let planetName = String?.earth

  // RIGHT
  let planetName: String? = .earth
  ```

  ```swift
  struct SaturnOutline: ShapeStyle { ... }

  extension ShapeStyle where Self == SaturnOutline {
    static var saturnOutline: SaturnOutline { 
      SaturnOutline() 
    }
  }

  // WRONG: fails with "error: static member 'saturnOutline' cannot be used on protocol metatype '(any ShapeStyle).Type'"
  let myShape2 = (any ShapeStyle).myShape

  // RIGHT: If the property's type is an existential / protocol type, moving the type
  // to the right-hand side will result in invalid code if the value is defined in an
  // extension like `extension ShapeStyle where Self == SaturnOutline`.
  // SwiftFormat autocorrect detects this case by checking for the existential `any` keyword.
  let myShape1: any ShapeStyle = .saturnOutline
  ```

  </details>

* <a id='omit-self'></a>(<a href='#omit-self'>link</a>) **Don't use `self` unless it's necessary for disambiguation or required by the language.** [![SwiftFormat: redundantSelf](https://img.shields.io/badge/SwiftFormat-redundantSelf-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#redundantSelf)

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

* <a id='upgrade-self'></a>(<a href='#upgrade-self'>link</a>) **Bind to `self` when upgrading from a weak reference.** [![SwiftFormat: strongifiedSelf](https://img.shields.io/badge/SwiftFormat-strongifiedSelf-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#strongifiedSelf)

  <details>

  ```swift
  // WRONG
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
        guard let self else { return }
        // Do work
        completion()
      }
    }
  }
  ```

  </details>

* <a id='trailing-commas'></a>(<a href='#trailing-commas'>link</a>) **Add a trailing comma after the last element of multi-line, multi-element comma-separated lists.* This includes arrays, dictionaries, function declarations, function calls, etc. Don't include a trailing comma if the list spans only a single line, or contains only a single element. [![SwiftFormat: trailingCommas](https://img.shields.io/badge/SwiftFormat-trailingCommas-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#trailingCommas)

  <details>

  ```swift
  // WRONG
  let terrestrialPlanets = [
    mercury,
    venus,
    earth,
    mars
  ]

  func buildSolarSystem(
    innerPlanets: [Planet],
    outerPlanets: [Planet]
  ) { ... }

  buildSolarSystem(
    innertPlanets: terrestrialPlanets,
    outerPlanets: gasGiants
  )

  // RIGHT
  let terrestrialPlanets = [
    mercury,
    venus,
    earth,
    mars,
  ]

  func buildSolarSystem(
    innerPlanets: [Planet],
    outerPlanets: [Planet],
  ) { ... }

  buildSolarSystem(
    innertPlanets: terrestrialPlanets,
    outerPlanets: gasGiants,
  )
  ```

  ```swift
  // WRONG: Omit the trailing comma in single-element lists.
  let planetsWithLife = [
    earth,
  ]

  func buildSolarSystem(
    _ planets: [Planet],
  )

  buildSolarSystem(
    terrestrialPlanets + gasGiants,
  )

  // RIGHT
  let planetsWithLife = [
    earth
  ]

  func buildSolarSystem(
    _ planets: [Planet]
  ) { ... }

  buildSolarSystem(
    terrestrialPlanets + gasGiants
  )
  ```

  </details>

* <a id='no-space-inside-collection-brackets'></a>(<a href='#no-space-inside-brackets'>link</a>) **There should be no spaces inside the brackets of collection literals.** [![SwiftFormat: spaceInsideBrackets](https://img.shields.io/badge/SwiftFormat-spaceInsideBrackets-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#spaceInsideBrackets)

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

* <a id='colon-spacing'></a>(<a href='#colon-spacing'>link</a>) **Colons should always be followed by a space, but not preceded by a space**. [![SwiftFormat: spaceAroundOperators](https://img.shields.io/badge/SwiftFormat-spaceAroundOperators-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#spacearoundoperators)

  <details>

  ```swift
  // WRONG
  let planet:CelestialObject = sun.planets[0]
  let planet : CelestialObject = sun.planets[0]

  // RIGHT
  let planet: CelestialObject = sun.planets[0]
  ```

  ```swift
  // WRONG
  class Planet : CelestialObject {
    // ...
  }

  // RIGHT
  class Planet: CelestialObject {
    // ...
  }
  ```

  ```swift
  // WRONG
  let moons: [Planet : Moon] = [
    mercury : [], 
    venus : [], 
    earth : [theMoon], 
    mars : [phobos,deimos],
  ]

  // RIGHT
  let moons: [Planet: Moon] = [
    mercury: [], 
    venus: [], 
    earth: [theMoon], 
    mars: [phobos,deimos],
  ]
  ```

  </details>

* <a id='return-arrow-spacing'></a>(<a href='#return-arrow-spacing'>link</a>) **Place a space on either side of a return arrow for readability.** [![SwiftFormat: spaceAroundOperators](https://img.shields.io/badge/SwiftFormat-spaceAroundOperators-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#spacearoundoperators)

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

* <a id='unnecessary-parens'></a>(<a href='#unnecessary-parens'>link</a>) **Omit unnecessary parentheses.** [![SwiftFormat: redundantParens](https://img.shields.io/badge/SwiftFormat-redundantParens-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#redundantParens)

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

* <a id='unnecessary-enum-arguments'></a> (<a href='#unnecessary-enum-arguments'>link</a>) **Omit enum associated values from case statements when all arguments are unlabeled.** [![SwiftFormat: redundantPattern](https://img.shields.io/badge/SwiftFormat-redundantPattern-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#redundantPattern)

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

* <a id='inline-let-when-destructuring'></a> (<a href='#inline-let-when-destructuring'>link</a>) **When destructuring an enum case or a tuple, place the `let` keyword inline, adjacent to each individual property assignment.** [![SwiftFormat: hoistPatternLet](https://img.shields.io/badge/SwiftFormat-hoistPatternLet-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#hoistPatternLet)

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

    1. **Consistency**: We should prefer to either _always_ inline the `let` keyword or _never_ inline the `let` keyword. In Airbnb's Swift codebase, we [observed](https://github.com/airbnb/swift/pull/126#discussion_r631979244) that inline `let` is used far more often in practice (especially when destructuring enum cases with a single associated value).

    2. **Clarity**: Inlining the `let` keyword makes it more clear which identifiers are part of the conditional check and which identifiers are binding new variables, since the `let` keyword is always adjacent to the variable identifier.

    ```swift
    // `let` is adjacent to the variable identifier, so it is immediately obvious
    // at a glance that these identifiers represent new variable bindings
    case .enumCaseWithSingleAssociatedValue(let string):
    case .enumCaseWithMultipleAssociatedValues(let string, let int):

    // The `let` keyword is quite far from the variable identifiers,
    // so it is less obvious that they represent new variable bindings
    case let .enumCaseWithSingleAssociatedValue(string):
    case let .enumCaseWithMultipleAssociatedValues(string, int):

    ```

  </details>

* <a id='attributes-on-prev-line'></a>(<a href='#attributes-on-prev-line'>link</a>) **Place attributes for functions, types, and computed properties on the line above the declaration**. [![SwiftFormat: wrapAttributes](https://img.shields.io/badge/SwiftFormat-wrapAttributes-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#wrapAttributes)

  <details>

  ```swift
  // WRONG
  @objc class Spaceship {

    @ViewBuilder var controlPanel: some View {
      // ...
    }

    @discardableResult func fly() -> Bool {
      // ...
    }

  }

  // RIGHT
  @objc
  class Spaceship {

    @ViewBuilder
    var controlPanel: some View {
      // ...
    }

    @discardableResult
    func fly() -> Bool {
      // ...
    }

  }
  ```

  </details>

* <a id='simple-stored-property-attributes-on-same-line'></a>(<a href='#simple-stored-property-attributes-on-same-line'>link</a>) **Place simple attributes for stored properties on the same line as the rest of the declaration**. Complex attributes with named arguments, or more than one unnamed argument, should be placed on the previous line. [![SwiftFormat: wrapAttributes](https://img.shields.io/badge/SwiftFormat-wrapAttributes-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#wrapAttributes)

  <details>

  ```swift
  // WRONG. These simple property wrappers should be written on the same line as the declaration. 
  struct SpaceshipDashboardView {

    @State
    private var warpDriveEnabled: Bool

    @ObservedObject
    private var lifeSupportService: LifeSupportService

    @Environment(\.controlPanelStyle) 
    private var controlPanelStyle

  }

  // RIGHT
  struct SpaceshipDashboardView {

    @State private var warpDriveEnabled: Bool

    @ObservedObject private var lifeSupportService: LifeSupportService

    @Environment(\.controlPanelStyle) private var controlPanelStyle

  }
  ```

  ```swift
  // WRONG. These complex attached macros should be written on the previous line.
  struct SolarSystemView {

    @Query(sort: \.distance) var allPlanets: [Planet]

    @Query(sort: \.age, order: .reverse) var moonsByAge: [Moon]

  }

  // RIGHT
  struct SolarSystemView {

    @Query(sort: \.distance)
    var allPlanets: [Planet]

    @Query(sort: \.age, order: .reverse)
    var oldestMoons: [Moon]

  }
  ```

  ```swift
  // WRONG. These long, complex attributes should be written on the previous line.
  struct RocketFactory {

    @available(*, unavailable, message: "No longer in production") var saturn5Builder: Saturn5Builder

    @available(*, deprecated, message: "To be retired by 2030") var atlas5Builder: Atlas5Builder

    @available(*, iOS 18.0, tvOS 18.0, macOS 15.0, watchOS 11.0) var newGlennBuilder: NewGlennBuilder

  }

  // RIGHT
  struct RocketFactory {

    @available(*, unavailable, message: "No longer in production")
    var saturn5Builder: Saturn5Builder

    @available(*, deprecated, message: "To be retired by 2030")
    var atlas5Builder: Atlas5Builder
    
    @available(*, iOS 18.0, tvOS 18.0, macOS 15.0, watchOS 11.0)
    var newGlennBuilder: NewGlennBuilder

  }
  ```
  
  #### Why?
  
  Unlike other types of declarations, which have braces and span multiple lines, stored property declarations are often only a single line of code. Stored properties are often written sequentially without any blank lines between them. This makes the code compact without hurting readability, and allows for related properties to be grouped together in blocks:
  
  ```swift
  struct SpaceshipDashboardView {
    @State private var warpDriveEnabled: Bool
    @State private var lifeSupportEnabled: Bool
    @State private var artificialGravityEnabled: Bool
    @State private var tractorBeamEnabled: Bool
    
    @Environment(\.controlPanelStyle) private var controlPanelStyle
    @Environment(\.toggleButtonStyle) private var toggleButtonStyle
  }
  ```
  
  If stored property attributes were written on the previous line (like other types of attributes), then the properties start to visually bleed together unless you add blank lines between them:
  
  ```swift
  struct SpaceshipDashboardView {
    @State
    private var warpDriveEnabled: Bool
    @State
    private var lifeSupportEnabled: Bool
    @State
    private var artificialGravityEnabled: Bool
    @State
    private var tractorBeamEnabled: Bool
    
    @Environment(\.controlPanelStyle)
    private var controlPanelStyle
    @Environment(\.toggleButtonStyle)
    private var toggleButtonStyle
  }
  ```
  
  If you add blank lines, the list of properties becomes much longer and you lose the ability to group related properties together:  
  
  ```swift
  struct SpaceshipDashboardView {
    @State
    private var warpDriveEnabled: Bool
    
    @State
    private var lifeSupportEnabled: Bool
    
    @State
    private var artificialGravityEnabled: Bool
    
    @State
    private var tractorBeamEnabled: Bool
    
    @Environment(\.controlPanelStyle)
    private var controlPanelStyle
    
    @Environment(\.toggleButtonStyle)
    private var toggleButtonStyle
  }
  ```
  
  This doesn't apply to complex attributes with named arguments, or multiple unnamed arguments. These arguments are visually complex and typically encode a lot of information, so feel cramped and difficult to read when written on a single line:

  ```swift
  // Despite being less than 100 characters long, these lines are very complex and feel unnecessarily long: 
  @available(*, unavailable, message: "No longer in production") var saturn5Builder: Saturn5Builder
  @available(*, deprecated, message: "To be retired by 2030") var atlas5Builder: Atlas5Builder
  @available(*, iOS 18.0, tvOS 18.0, macOS 15.0, watchOS 11.0) var newGlennBuilder: NewGlennBuilder
  ```

  </details>

* <a id='modifiers-on-same-line'></a>(<a href='#modifiers-on-same-line'>link</a>) **Place modifiers for a declaration on the same line as the rest of the declaration**. [![SwiftFormat: modifiersOnSameLine](https://img.shields.io/badge/SwiftFormat-modifiersOnSameLine-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#modifiersOnSameLine)

  <details>

  ```swift
  // WRONG
  public struct Spaceship {
    nonisolated
    public func fly() { … }

    @MainActor
    public
    func fly() { … }
  }

  // RIGHT
  public struct Spaceship {
    nonisolated public func fly() { … }

    @MainActor
    public func fly() { … }
  }
  ```

  </details>

* <a id='multi-line-array'></a>(<a href='#multi-line-array'>link</a>) **Multi-line arrays should have each bracket on a separate line.** Put the opening and closing brackets on separate lines from any of the elements of the array. Also add a trailing comma on the last element. [![SwiftFormat: wrapArguments](https://img.shields.io/badge/SwiftFormat-wrapArguments-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#wrapArguments)

  <details>

  ```swift
  // WRONG
  let rowContent = [listingUrgencyDatesRowContent(),
                    listingUrgencyBookedRowContent(),
                    listingUrgencyBookedShortRowContent()]

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

* <a id='long-typealias'></a>(<a href='#long-typealias'>link</a>) [Long](https://github.com/airbnb/swift#column-width) type aliases of protocol compositions should wrap before the `=` and before each individual `&`. [![SwiftFormat: wrapArguments](https://img.shields.io/badge/SwiftFormat-wrapArguments-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#wrapArguments)

  <details>

  ```swift
  // WRONG (too long)
  public typealias Dependencies = CivilizationServiceProviding & LawsOfPhysicsProviding & PlanetBuilderProviding & UniverseBuilderProviding & UniverseSimulatorServiceProviding

  // WRONG (naive wrapping)
  public typealias Dependencies = CivilizationServiceProviding & LawsOfPhysicsProviding & PlanetBuilderProviding &
    UniverseBuilderProviding & UniverseSimulatorServiceProviding

  // WRONG (unbalanced)
  public typealias Dependencies = CivilizationServiceProviding
    & LawsOfPhysicsProviding
    & PlanetBuilderProviding
    & UniverseBuilderProviding
    & UniverseSimulatorServiceProviding

  // RIGHT
  public typealias Dependencies
    = CivilizationServiceProviding
    & LawsOfPhysicsProviding
    & PlanetBuilderProviding
    & UniverseBuilderProviding
    & UniverseSimulatorServiceProviding
  ```

* <a id='sort-typealiases'></a>(<a href='#sort-typealiases'>link</a>) **Sort protocol composition type aliases alphabetically.** [![SwiftFormat: sortTypealiases](https://img.shields.io/badge/SwiftFormat-sortTypealiases-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#sortTypealiases)

  <details>

  #### Why?

  Protocol composition type aliases are an unordered list with no natural ordering. Sorting alphabetically keeps these lists more organized, which is especially valuable for long protocol compositions.

  ```swift
  // WRONG (not sorted)
  public typealias Dependencies
    = UniverseBuilderProviding
    & LawsOfPhysicsProviding
    & UniverseSimulatorServiceProviding
    & PlanetBuilderProviding
    & CivilizationServiceProviding

  // RIGHT
  public typealias Dependencies
    = CivilizationServiceProviding
    & LawsOfPhysicsProviding
    & PlanetBuilderProviding
    & UniverseBuilderProviding
    & UniverseSimulatorServiceProviding
  ```

* <a id='prefer-if-let-shorthand'></a>(<a href='#prefer-if-let-shorthand'>link</a>) Omit the right-hand side of the expression when unwrapping an optional property to a non-optional property with the same name. [![SwiftFormat: redundantOptionalBinding](https://img.shields.io/badge/SwiftFormat-redundantOptionalBinding-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#redundantOptionalBinding)

  <details>

  #### Why?

  Following the rationale in [SE-0345](https://github.com/apple/swift-evolution/blob/main/proposals/0345-if-let-shorthand.md), this shorthand syntax removes unnecessary boilerplate while retaining clarity.

  ```swift
  // WRONG
  if
    let galaxy = galaxy,
    galaxy.name == "Milky Way"
  { … }

  guard
    let galaxy = galaxy,
    galaxy.name == "Milky Way"
  else { … }

  // RIGHT
  if
    let galaxy,
    galaxy.name == "Milky Way"
  { … }

  guard
    let galaxy,
    galaxy.name == "Milky Way"
  else { … }
  ```

* <a id='else-on-same-line'></a>(<a href='#else-on-same-line'>link</a>) **Else statements should start on the same line as the previous condition's closing brace, unless the conditions are separated by a blank line or comments.** [![SwiftFormat: elseOnSameLine](https://img.shields.io/badge/SwiftFormat-elseOnSameLine-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#elseOnSameLine)

  <details>

  ```swift
  // WRONG
  if let galaxy {
    …
  }
  else if let bigBangService {
    …
  }
  else {
    …
  }

  // RIGHT
  if let galaxy {
    …
  } else if let bigBangService {
    …
  } else {
    …
  }

  // RIGHT, because there are comments between the conditions
  if let galaxy {
    …
  }
  // If the galaxy hasn't been created yet, create it using the big bang service
  else if let bigBangService {
    …
  }
  // If the big bang service doesn't exist, fail gracefully
  else {
    …
  }

  // RIGHT, because there are blank lines between the conditions
  if let galaxy {
    …
  }

  else if let bigBangService {
    // If the galaxy hasn't been created yet, create it using the big bang service
    …
  }

  else {
    // If the big bang service doesn't exist, fail gracefully
    …
  }
  ```

* <a id='multi-line-conditions'></a>(<a href='#multi-line-conditions'>link</a>) **Multi-line conditional statements should break after the leading keyword.** Indent each individual statement by [2 spaces](https://github.com/airbnb/swift#spaces-over-tabs). [![SwiftFormat: wrapArguments](https://img.shields.io/badge/SwiftFormat-wrapArguments-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#wrapArguments)

  <details>

  #### Why?
  Breaking after the leading keyword resets indentation to the standard [2-space grid](https://github.com/airbnb/swift#spaces-over-tabs),
  which helps avoid fighting Xcode's <kbd>^</kbd> + <kbd>I</kbd> indentation behavior.

  ```swift
  // WRONG
  if let galaxy,
    galaxy.name == "Milky Way" // Indenting by two spaces fights Xcode's ^+I indentation behavior
  { … }

  // WRONG
  guard let galaxy,
        galaxy.name == "Milky Way" // Variable width indentation (6 spaces)
  else { … }

  // WRONG
  guard let earth = universe.find(
    .planet,
    named: "Earth"),
    earth.isHabitable // Blends in with previous condition's method arguments
  else { … }

  // RIGHT
  if
    let galaxy,
    galaxy.name == "Milky Way"
  { … }

  // RIGHT
  guard
    let galaxy,
    galaxy.name == "Milky Way"
  else { … }

  // RIGHT
  guard
    let earth = universe.find(
      .planet,
      named: "Earth"),
    earth.isHabitable
  else { … }

  // RIGHT
  if let galaxy {
    …
  }

  // RIGHT
  guard let galaxy else {
    …
  }
  ```
  
  </details>

* <a id='wrap-multiline-conditional-assignment'></a>(<a href='#wrap-multiline-conditional-assignment'>link</a>) **Add a line break after the assignment operator (`=`) before a multi-line `if` or `switch` expression**, and indent the following `if` / `switch` expression. If the declaration fits on a single line, a line break is not required. [![SwiftFormat: wrapMultilineConditionalAssignment](https://img.shields.io/badge/SwiftFormat-wrapMultilineConditionalAssignment-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#wrapMultilineConditionalAssignment)

  <details>

  #### Why?
  
  This makes it so that `if` and `switch` expressions always have the same "shape" as standard `if` and `switch` statements, where:
  1. The `if` / `switch` keyword is always the left-most token on a dedicated line of code.
  2. The conditional branches are always to the right of and below the `if` / `switch` keyword.

  This is most consistent with how the `if` / `switch` keywords are used for control flow, and thus makes it easier to recognize that the code is using an `if` or `switch` expression at a glance. 
  
  ```swift
  // WRONG. Should have a line break after the first `=`. 
  let planetLocation = if let star = planet.star {
    "The \(star.name) system"
   } else {
    "Rogue planet"
  }

  // WRONG. The first `=` should be on the line of the variable being assigned.
  let planetLocation 
    = if let star = planet.star {
      "The \(star.name) system"
    } else {
      "Rogue planet"
    }

  // WRONG. `switch` expression should be indented.
  let planetLocation =
  switch planet {
  case .mercury, .venus, .earth, .mars:
    .terrestrial
  case .jupiter, .saturn, .uranus, .neptune:
    .gasGiant
  }
    
  // RIGHT 
  let planetLocation = 
    if let star = planet.star {
      "The \(star.name) system"
    } else {
      "Rogue planet"
    }
    
  // RIGHT
  let planetType: PlanetType =
    switch planet {
    case .mercury, .venus, .earth, .mars:
      .terrestrial
    case .jupiter, .saturn, .uranus, .neptune:
      .gasGiant
    }
    
  // ALSO RIGHT. A line break is not required because the declaration fits on a single line. 
  let moonName = if let moon = planet.moon { moon.name } else { "none" }

  // ALSO RIGHT. A line break is permitted if it helps with readability.
  let moonName =
    if let moon = planet.moon { moon.name } else { "none" }
  ```
  
  </details>

* <a id='prefer-conditional-assignment-to-control-flow'></a>(<a href='#prefer-conditional-assignment-to-control-flow'>link</a>) **When initializing a new property with the result of a conditional statement (e.g. an `if` or `switch` statement), use a single `if`/`switch` expression where possible** rather than defining an uninitialized property and initializing it on every branch of the following conditional statement. [![SwiftFormat: conditionalAssignment](https://img.shields.io/badge/SwiftFormat-conditionalAssignment-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#conditionalAssignment)

  <details>

  #### Why?

  There are several benefits to using an `if`/`switch` expression over simply performing assignment on each branch of the following conditional statement:
  1. In most cases, you no longer need to explicitly write a type annotation for the variable that is being assigned to.
  2. The compiler will diagnose more cases where using a mutable `var` is unnecessary.
  3. The resulting syntax is visually lighter because the property name being assigned doesn't need to be written on each branch.

  ```swift
  // BEFORE
  // 1. An explicit type annotation is required for the uninitialized property.
  // 2. `var` is unnecessary here because `planetLocation` is never modified after being initialized, but the compiler doesn't diagnose.
  // 3. The `planetLocation` property name is written on each branch so is redundant and visually noisy.
  var planetLocation: String
  if let star = planet.star {
    planetLocation = "The \(star.name) system"
  } else {
    planetLocation = "Rogue planet"
  }

  print(planetLocation)

  // AFTER
  // 1. No need to write an explicit `: String` type annotation.
  // 2. The compiler correctly diagnoses that the `var` is unnecessary and emits a warning suggesting to use `let` instead. 
  // 3. Each conditional branch is simply the value being assigned.
  var planetLocation =
    if let star = planet.star {
      "The \(star.name) system"
    } else {
      "Rogue planet"
    }

  print(planetLocation)
  ```

  #### Examples

  ```swift
  // WRONG
  let planetLocation: String
  if let star = planet.star {
    planetLocation = "The \(star.name) system"
  } else {
    planetLocation = "Rogue planet"
  }

  let planetType: PlanetType
  switch planet {
  case .mercury, .venus, .earth, .mars:
    planetType = .terrestrial
  case .jupiter, .saturn, .uranus, .neptune:
    planetType = .gasGiant
  }

  let canBeTerraformed: Bool 
  if 
    let star = planet.star, 
    !planet.isHabitable,
    planet.isInHabitableZone(of: star) 
  {
    canBeTerraformed = true
  } else {
    canBeTerraformed = false
  }

  // RIGHT
  let planetLocation =
    if let star = planet.star {
      "The \(star.name) system"
    } else {
      "Rogue planet"
    }

  let planetType: PlanetType =
    switch planet {
    case .mercury, .venus, .earth, .mars:
      .terrestrial
    case .jupiter, .saturn, .uranus, .neptune:
      .gasGiant
    }

  let canBeTerraformed =
    if 
      let star = planet.star, 
      !planet.isHabitable,
      planet.isInHabitableZone(of: star) 
    {
      true
    } else {
      false
    }

  // ALSO RIGHT. This example cannot be converted to an if/switch expression
  // because one of the branches is more than just a single expression.
  let planetLocation: String
  if let star = planet.star {
    planetLocation = "The \(star.name) system"
  } else {
    let actualLocaton = galaxy.name ?? "the universe"
    planetLocation = "Rogue planet somewhere in \(actualLocation)"
  }
  ```

  </details>

* <a id='blank-line-after-multiline-switch-case'></a>(<a href='#blank-line-after-multiline-switch-case'>link</a>) **Insert a blank line following a switch case with a multi-line body.** Spacing within an individual switch statement should be consistent. If any case has a multi-line body then all cases should include a trailing blank line. The last switch case doesn't need a blank line, since it is already followed by a closing brace. [![SwiftFormat: blankLineAfterSwitchCase](https://img.shields.io/badge/SwiftFormat-blankLineAfterSwitchCase-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#blankLineAfterSwitchCase) [![SwiftFormat: consistentSwitchCaseSpacing](https://img.shields.io/badge/SwiftFormat-consistentSwitchCaseSpacing-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#consistentSwitchCaseSpacing)

  <details>

  #### Why?

  Like with [declarations in a file](#newline-between-scope-siblings), inserting a blank line between scopes makes them easier to visually differentiate.
  
  Complex switch statements are visually busy without blank lines between the cases, making it more difficult to read the code and harder to distinguish between individual cases at a glance. Blank lines between the individual cases make complex switch statements easier to read.

  #### Examples

  ```swift
  // WRONG. These switch cases should be followed by a blank line.
  func handle(_ action: SpaceshipAction) {
    switch action {
    case .engageWarpDrive:
      navigationComputer.destination = targetedDestination
      warpDrive.spinUp()
      warpDrive.activate()
    case .enableArtificialGravity:
      artificialGravityEngine.enable(strength: .oneG)
    case .scanPlanet(let planet):
      scanner.target = planet
      scanner.scanAtmosphere()
      scanner.scanBiosphere()
      scanner.scanForArtificialLife()
    case .handleIncomingEnergyBlast:
      energyShields.engage()
    }
  }

  // WRONG. While the `.enableArtificialGravity` case isn't multi-line, the other cases are.
  // For consistency, it should also include a trailing blank line.
  func handle(_ action: SpaceshipAction) {
    switch action {
    case .engageWarpDrive:
      navigationComputer.destination = targetedDestination
      warpDrive.spinUp()
      warpDrive.activate()

    case .enableArtificialGravity:
      artificialGravityEngine.enable(strength: .oneG)
    case .scanPlanet(let planet):
      scanner.target = planet
      scanner.scanAtmosphere()
      scanner.scanBiosphere()
      scanner.scanForArtificialLife()
      
    case .handleIncomingEnergyBlast:
      energyShields.engage()
    }
  }

  // RIGHT. All of the cases have a trailing blank line.
  func handle(_ action: SpaceshipAction) {
    switch action {
    case .engageWarpDrive:
      navigationComputer.destination = targetedDestination
      warpDrive.spinUp()
      warpDrive.activate()

    case .enableArtificialGravity:
      artificialGravityEngine.enable(strength: .oneG)

    case .scanPlanet(let planet):
      scanner.target = planet
      scanner.scanAtmosphere()
      scanner.scanBiosphere()
      scanner.scanForArtificialLife()
      
    case .handleIncomingEnergyBlast:
      energyShields.engage()
    }
  }

  // RIGHT. Since none of the cases are multi-line, blank lines are not required.
  func handle(_ action: SpaceshipAction) {
    switch action {
    case .engageWarpDrive:
      warpDrive.engage()
    case .enableArtificialGravity:
      artificialGravityEngine.enable(strength: .oneG)
    case .scanPlanet(let planet):
      scanner.scan(planet)
    case .handleIncomingEnergyBlast:
      energyShields.engage()
    }
  }

  // ALSO RIGHT. Blank lines are still permitted after single-line switch cases if it helps with readability.
  func handle(_ action: SpaceshipAction) {
    switch action {
    case .engageWarpDrive:
      warpDrive.engage()

    case .enableArtificialGravity:
      artificialGravityEngine.enable(strength: .oneG)

    case .scanPlanet(let planet):
      scanner.scan(planet)

    case .handleIncomingEnergyBlast:
      energyShields.engage()
    }
  }

  // WRONG. While it's fine to use blank lines to separate cases, spacing within a single switch statement should be consistent.
  func handle(_ action: SpaceshipAction) {
    switch action {
    case .engageWarpDrive:
      warpDrive.engage()
    case .enableArtificialGravity:
      artificialGravityEngine.enable(strength: .oneG)
    case .scanPlanet(let planet):
      scanner.scan(planet)

    case .handleIncomingEnergyBlast:
      energyShields.engage()
    }
  }
  ```

  </details>

* <a id='omit-redundant-break'></a>(<a href='#omit-redundant-break'>link</a>) **Omit redundant `break` statements in switch cases.** [![SwiftFormat: redundantBreak](https://img.shields.io/badge/SwiftFormat-redundantBreak-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#redundantBreak)

  <details>

  #### Why?
  Swift automatically breaks out of a switch case after executing its code, so explicit `break` statements are usually unnecessary and add visual clutter.

  ```swift
  // WRONG
  switch spaceship.warpDriveState {
  case .engaged:
    navigator.engageWarpDrive()
    break
  case .disengaged:
    navigator.disengageWarpDrive()
    break
  }

  // RIGHT  
  switch spaceship.warpDriveState {
  case .engaged:
    navigator.engageWarpDrive()
  case .disengaged:
    navigator.disengageWarpDrive()
  }
  ```

  </details>

* <a id='wrap-guard-else'></a>(<a href='#wrap-guard-else'>link</a>) **Add a line break before the `else` keyword in a multi-line guard statement.** For single-line guard statements, keep the `else` keyword on the same line as the `guard` keyword. The open brace should immediately follow the `else` keyword. [![SwiftFormat: elseOnSameLine](https://img.shields.io/badge/SwiftFormat-elseOnSameLine-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#elseOnSameLine)

  <details>

  ```swift
  // WRONG (else should be on its own line for multi-line guard statements)
  guard
    let galaxy,
    galaxy.name == "Milky Way" else
  { … }

  // WRONG (else should be on the same line for single-line guard statements)
  guard let galaxy
  else { … }

  // RIGHT
  guard
    let galaxy,
    galaxy.name == "Milky Way"
  else { … }

  // RIGHT
  guard let galaxy else {
    …
  }
  ```

* <a id='indent-multiline-string-literals'></a>(<a href='#indent-multiline-string-literals'>link</a>) **Indent the body and closing triple-quote of multiline string literals**, unless the string literal begins on its own line in which case the string literal contents and closing triple-quote should have the same indentation as the opening triple-quote. [![SwiftFormat: indent](https://img.shields.io/badge/SwiftFormat-indent-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#indent)

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

* <a id='standard-library-type-shorthand'></a>(<a href='#standard-library-type-sugar'>link</a>) **For standard library types with a canonical shorthand form (`Optional`, `Array`, `Dictionary`), prefer using the shorthand form over the full generic form.** [![SwiftFormat: typeSugar](https://img.shields.io/badge/SwiftFormat-typeSugar-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#typeSugar)

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

* <a id='omit-explicit-init'></a>(<a href='#omit-explicit-init'>link</a>) **Omit explicit `.init` when not required.** [![SwiftFormat: redundantInit](https://img.shields.io/badge/SwiftFormat-redundantInit-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#redundantInit)

  <details>

  ```swift
  // WRONG
  let universe = Universe.init()

  // RIGHT
  let universe = Universe()
  ```

  </details>

* <a id='single-line-expression-braces'></a>(<a href='#single-line-expression-braces'>link</a>) The opening brace following a single-line expression should be on the same line as the rest of the statement. [![SwiftFormat: braces](https://img.shields.io/badge/SwiftFormat-braces-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#braces)

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

* <a id='multi-line-expression-braces'></a>(<a href='#multi-line-expression-braces'>link</a>) The opening brace following a multi-line expression should wrap to a new line. [![SwiftFormat: wrapMultilineStatementBraces](https://img.shields.io/badge/SwiftFormat-wrapMultilineStatementBraces-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#wrapMultilineStatementBraces)

  <details>

  ```swift
  // WRONG
  if
    let star = planet.nearestStar(),
    planet.isInHabitableZone(of: star) {
    planet.terraform()
  }

  // RIGHT
  if
    let star = planet.nearestStar(),
    planet.isInHabitableZone(of: star)
  {
    planet.terraform()
  }
  ```

  </details>

* <a id='whitespace-around-braces'></a>(<a href='#whitespace-around-braces'>link</a>) **Braces should be surrounded by a single whitespace character (either a space, or a newline) on each side.** [![SwiftFormat: spaceInsideBraces](https://img.shields.io/badge/SwiftFormat-spaceInsideBraces-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#spaceInsideBraces) [![SwiftFormat: spaceAroundBraces](https://img.shields.io/badge/SwiftFormat-spaceAroundBraces-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#spaceAroundBraces)

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

* <a id='no-spaces-around-function-parens'></a>(<a href='#no-spaces-around-parens'>link</a>) For function calls and declarations, there should be no spaces before or inside the parentheses of the argument list. [![SwiftFormat: spaceInsideParens](https://img.shields.io/badge/SwiftFormat-spaceInsideParens-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#spaceInsideParens) [![SwiftFormat: spaceAroundParens](https://img.shields.io/badge/SwiftFormat-spaceAroundParens-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#spaceAroundParens)

  <details>

  ```swift
  // WRONG
  func install ( _ engine: Engine ) { }

  install ( AntimatterDrive( ) )

  // RIGHT
  func install(_ engine: Engine) { }

  install(AntimatterDrive())
  ```

  </details>

* <a id='single-line-comments'></a>(<a href='#single-line-comments'>link</a>) **Comment blocks should use single-line comments (`//` for code comments and `///` for documentation comments)**, rather than multi-line comments (`/* ... */` and `/** ... */`). [![SwiftFormat: blockComments](https://img.shields.io/badge/SwiftFormat-blockComments-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#blockComments)

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

* <a id='doc-comments-before-declarations'></a>(<a href='#doc-comments-before-declarations'>link</a>) **Use doc comments (`///`) instead of regular comments (`//`) before declarations within type bodies or at the top level.** [![SwiftFormat: docComments](https://img.shields.io/badge/SwiftFormat-docComments-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#docComments)

  <details>

  ```swift
  // WRONG

  // A planet that exists somewhere in the universe.
  class Planet {
    // Data about the composition and density of the planet's atmosphere if present.
    var atmosphere: Atmosphere?

    // Data about the size, location, and composition of large bodies of water on the planet's surface.
    var oceans: [Ocean]

    // Terraforms the planet, by adding an atmosphere and ocean that is hospitable for life.
    func terraform() {
      // This gas composition has a pretty good track record so far!
      let composition = AtmosphereComposition(nitrogen: 0.78, oxygen: 0.22)

      // Generate the atmosphere first, then the oceans. Otherwise, the water will just boil off immediately.
      generateAtmosphere(using: composition)
      generateOceans()
    }
  }

  // RIGHT

  /// A planet that exists somewhere in the universe.
  class Planet {
    /// Data about the composition and density of the planet's atmosphere if present.
    var atmosphere: Atmosphere?

    /// Data about the size, location, and composition of large bodies of water on the planet's surface.
    var oceans: [Ocean]

    /// Terraforms the planet, by adding an atmosphere and ocean that is hospitable for life.
    func terraform() {
      // This gas composition has a pretty good track record so far!
      let composition = AtmosphereComposition(nitrogen: 0.78, oxygen: 0.22)

      // Generate the atmosphere first, then the oceans. Otherwise, the water will just boil off immediately.
      generateAtmosphere(using: composition)
      generateOceans()
    }
  }
  
  // ALSO RIGHT:

  func terraform() {
    /// This gas composition has a pretty good track record so far!
    ///  - Doc comments are not required before local declarations in function scopes, but are permitted.
    let composition = AtmosphereComposition(nitrogen: 0.78, oxygen: 0.22)

    /// Generate the `atmosphere` first, **then** the `oceans`. Otherwise, the water will just boil off immediately.
    ///  - Comments not preceding declarations can use doc comments, and will not be autocorrected into regular comments.
    ///    This can be useful because Xcode applies markdown styling to doc comments but not regular comments.
    generateAtmosphere(using: composition)
    generateOceans()
  }
  ```

  Regular comments are permitted before declarations in some cases. 
  
  For example, comment directives like `// swiftformat:`, `// swiftlint:`, `// sourcery:`, `// MARK:` and `// TODO:` are typically required to use regular comments and don't work correctly with doc comments:

  ```swift
  // RIGHT

  // swiftformat:sort
  enum FeatureFlags {
    case allowFasterThanLightTravel
    case disableGravity
    case enableDarkEnergy
    case enableDarkMatter
  }

  // TODO: There are no more production consumers of this legacy model, so we
  // should detangle the remaining code dependencies and clean it up.
  struct LegacyGeocentricUniverseModel {
    ...
  }
  ```

  Regular comments are also allowed before a grouped block of declarations, since it's possible that the comment refers to the block as a whole rather than just the following declaration:

  ```swift
  // RIGHT

  enum Planet {
    // The inner planets
    case mercury
    case venus
    case earth
    case mars

    // The outer planets
    case jupiter
    case saturn
    case uranus
    case neptune
  }

  // ALSO RIGHT

  enum Planet {
    /// The smallest planet
    case mercury
    case venus
    case earth
    case mars
    /// The largest planet
    case jupiter
    case saturn
    case uranus
    case neptune
  }
  ```

  </details>

* <a id='doc-comments-before-attributes'></a>(<a href='#doc-comments-before-attributes'>link</a>) **Place doc comments for a declaration before any attributes or modifiers.** [![SwiftFormat: docCommentsBeforeModifiers](https://img.shields.io/badge/SwiftFormat-docCommentsBeforeModifiers-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#docCommentsBeforeModifiers)

  <details>

  ```swift
  // WRONG

  @MainActor
  /// A spacecraft with everything you need to explore the universe.
  struct Spaceship { … }

  public
  /// A spacecraft with everything you need to explore the universe.
  struct Spaceship { … }

  // RIGHT

  /// A spacecraft with everything you need to explore the universe.
  @MainActor
  struct Spaceship { … }

  /// A spacecraft with everything you need to explore the universe.
  public struct Spaceship { … }
  ```

  </details>

* <a id='whitespace-around-comment-delimiters'></a>(<a href='#whitespace-around-comment-delimiters'>link</a>) Include spaces or newlines before and after comment delimiters (`//`, `///`, `/*`, and `*/`) [![SwiftFormat: spaceAroundComments](https://img.shields.io/badge/SwiftFormat-spaceAroundComments-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#spaceAroundComments) [![SwiftFormat: spaceInsideComments](https://img.shields.io/badge/SwiftFormat-spaceInsideComments-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#spaceInsideComments)

  <details>

  ```swift
  // WRONG

  ///A spacecraft with incredible performance characteristics
  struct Spaceship {

    func travelFasterThanLight() {/*unimplemented*/}

    func travelBackInTime() { }//TODO: research whether or not this is possible

  }

  // RIGHT

  /// A spacecraft with incredible performance characteristics
  struct Spaceship {

    func travelFasterThanLight() { /* unimplemented */ }

    func travelBackInTime() { } // TODO: research whether or not this is possible

  }
  ```

  </details>

* <a id='space-in-empty-braces'></a>(<a href='#space-in-empty-braces'>link</a>) Include a single space in an empty set of braces (`{ }`). [![SwiftFormat: emptyBraces](https://img.shields.io/badge/SwiftFormat-emptyBraces-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#emptyBraces)

  <details>

  ```swift
  // WRONG
  extension Spaceship: Trackable {}

  extension SpaceshipView {
    var accessibilityIdentifier: String {
      get { spaceship.name }
      set {}
    }
  }

  // RIGHT
  extension Spaceship: Trackable { }

  extension SpaceshipView {
    var accessibilityIdentifier: String {
      get { spaceship.name }
      set { }
    }
  }
  ```

  </details>

* <a id='prefer-for-loop-over-forEach'></a>(<a href='#prefer-for-loop-over-forEach'>link</a>) **Prefer using `for` loops over the functional `forEach(…)` method**, unless using `forEach(…)` as the last element in a functional chain. [![SwiftFormat: forLoop](https://img.shields.io/badge/SwiftFormat-forLoop-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#forLoop)

  <details>

  #### Why?
  For loops are more idiomatic than the `forEach(…)` method, and are typically familiar to all developers who have experience with C-family languages. 

  For loops are also more expressive than the `forEach(…)` method. For loops support the `return`, `continue`, and `break` control flow keywords, while `forEach(…)` only supports `return` (which has the same behavior as `continue` in a for loop).
  
  ```swift
  // WRONG
  planets.forEach { planet in
    planet.terraform()
  }

  // WRONG
  planets.forEach {
    $0.terraform()
  }

  // RIGHT
  for planet in planets {
    planet.terraform()
  }

  // ALSO FINE, since forEach is useful when paired with other functional methods in a chain.
  planets
    .filter { !$0.isGasGiant }
    .map { PlanetTerraformer(planet: $0) }
    .forEach { $0.terraform() }
  ```
    
  </details>

* <a id='omit-internal-keyword'></a>(<a href='#omit-internal-keyword'>link</a>) **Omit the `internal` keyword** when defining types, properties, or functions with an internal access control level. [![SwiftFormat: redundantInternal](https://img.shields.io/badge/SwiftFormat-redundantInternal-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#redundantInternal)

  <details>

  ```swift
  // WRONG
  internal class Spaceship {
    internal init() { … }
    internal func travel(to planet: Planet) { … }
  }

  // RIGHT, because internal access control is implied if no other access control level is specified.
  class Spaceship {
    init() { … }
    func travel(to planet: Planet) { … }
  }
  ```

  </details>

* <a id='omit-redundant-public'></a>(<a href='#omit-redundant-public'>link</a>) **Avoid using `public` access control in `internal` types.** In this case the `public` modifier is redundant and has no effect. [![SwiftFormat: redundantPublic](https://img.shields.io/badge/SwiftFormat-redundantPublic-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#redundantPublic)

  <details>

  ```swift
  // WRONG: Public declarations in internal types are internal, not public.
  class Spaceship {
    public init() { … }
    public func travel(to planet: Planet) { … }
  }

  // RIGHT
  class Spaceship {
    init() { … }
    func travel(to planet: Planet) { … }
  }
  ```

  </details>

### Functions

* <a id='omit-function-void-return'></a>(<a href='#omit-function-void-return'>link</a>) **Omit `Void` return types from function definitions.** [![SwiftFormat: redundantVoidReturnType](https://img.shields.io/badge/SwiftFormat-redundantVoidReturnType-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#redundantVoidReturnType)

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

* <a id='long-function-declaration'></a>(<a href='#long-function-declaration'>link</a>) **Separate [long](https://github.com/airbnb/swift#column-width) function declarations with line breaks before each argument label, and before the closing parenthesis (`)`).** [![SwiftFormat: wrapArguments](https://img.shields.io/badge/SwiftFormat-wrapArguments-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#wrapArguments) [![SwiftFormat: braces](https://img.shields.io/badge/SwiftFormat-braces-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#braces) 

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

    // WRONG
    func generateStars(
      at location: Point,
      count: Int,
      color: StarColor,
      withAverageDistance averageDistance: Float) async throws // these effects are easy to miss since they're visually associated with the last parameter
      -> String
    {
      populateUniverse()
    }

    // RIGHT
    func generateStars(
      at location: Point,
      count: Int,
      color: StarColor,
      withAverageDistance averageDistance: Float
    ) -> String {
      populateUniverse()
    }

    // RIGHT
    func generateStars(
      at location: Point,
      count: Int,
      color: StarColor,
      withAverageDistance averageDistance: Float
    ) async throws -> String {
      populateUniverse()
    }
  }
  ```

  </details>

* <a id='long-function-invocation'></a>(<a href='#long-function-invocation'>link</a>) **[Long](https://github.com/airbnb/swift#column-width) function calls should also break on each argument.** Put the closing parenthesis on its own line. [![SwiftFormat: wrapArguments](https://img.shields.io/badge/SwiftFormat-wrapArguments-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#wrapArguments)

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
    withAverageDistance: 4)

  // WRONG
  universe.generate(5,
    .stars,
    at: location)

  // RIGHT
  universe.generateStars(
    at: location,
    count: 5,
    color: starColor,
    withAverageDistance: 4
  )

  // RIGHT
  universe.generate(
    5,
    .stars,
    at: location
  )
  ```

  </details>

* <a id='unused-function-parameter-naming'></a>(<a href='#unused-function-parameter-naming'>link</a>) **Name unused function parameters as underscores (`_`).** [![SwiftFormat: unusedArguments](https://img.shields.io/badge/SwiftFormat-unusedArguments-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#unusedArguments)

    <details>

    #### Why?
    Naming unused function parameters as underscores makes it more clear when the parameter is unused within the function body.
    This can make it easier to catch subtle logical errors, and can highlight opportunities to simplify method signatures.

    ```swift
    // WRONG

    // In this method, the `newCondition` parameter is unused.
    // This is actually a logical error, and is easy to miss, but compiles without warning.
    func updateWeather(_ newCondition: WeatherCondition) -> Weather {
      var updatedWeather = self
      updatedWeather.condition = condition // this mistake inadvertently makes this method unable to change the weather condition
      return updatedWeather
    }

    // In this method, the `color` parameter is unused.
    // Is this a logical error (e.g. should it be passed through to the `universe.generateStars` method call),
    // or is this an unused argument that should be removed from the method signature?
    func generateUniverseWithStars(
      at location: Point,
      count: Int,
      color: StarColor,
      withAverageDistance averageDistance: Float
    ) {
      let universe = generateUniverse()
      universe.generateStars(
        at: location,
        count: count,
        withAverageDistance: averageDistance
      )
    }
    ```

    ```swift
    // RIGHT

    // Automatically reformatting the unused parameter to be an underscore
    // makes it more clear that the parameter is unused, which makes it
    // easier to spot the logical error.
    func updateWeather(_: WeatherCondition) -> Weather {
      var updatedWeather = self
      updatedWeather.condition = condition
      return updatedWeather
    }

    // The underscore makes it more clear that the `color` parameter is unused.
    // This method argument can either be removed if truly unnecessary,
    // or passed through to `universe.generateStars` to correct the logical error.
    func generateUniverseWithStars(
      at location: Point,
      count: Int,
      color _: StarColor,
      withAverageDistance averageDistance: Float
    ) {
      let universe = generateUniverse()
      universe.generateStars(
        at: location,
        count: count,
        withAverageDistance: averageDistance
      )
    }
    ```

    </details>

* <a id='remove-blank-lines-between-chained-functions'></a>(<a href='#remove-blank-lines-between-chained-functions'>link</a>) **Remove blank lines between chained functions.** [![SwiftFormat: blanklinesbetweenchainedfunctions](https://img.shields.io/badge/SwiftFormat-blankLinesBetweenChainedFunctions-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#blanklinesbetweenchainedfunctions)

  <details>

  #### Why?

  Improves readability and maintainability, making it easier to see the sequence of functions that are applied to the object.

  ```swift
  // WRONG
  var innerPlanetNames: [String] {
    planets
      .filter { $0.isInnerPlanet }

      .map { $0.name }
  }

  // WRONG
  var innerPlanetNames: [String] {
    planets
      .filter { $0.isInnerPlanet }

      // Gets the name of the inner planet
      .map { $0.name }
  }

  // RIGHT
  var innerPlanetNames: [String] {
    planets
      .filter { $0.isInnerPlanet }
      .map { $0.name }
  }

  // RIGHT
  var innerPlanetNames: [String] {
    planets
      .filter { $0.isInnerPlanet }
      // Gets the name of the inner planet
      .map { $0.name }
  }
  ```

  </details>

* <a id='omit-redundant-typed-throws'></a>(<a href='#omit-redundant-typed-throws'>link</a>) **Omit redundant typed `throws` annotations from function definitions.** [![SwiftFormat: redundantTypedThrows](https://img.shields.io/badge/SwiftFormat-redundantTypedThrows-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#redundantTypedThrows)

  <details>

  #### Why?
  `throws(Never)` is equivalent to a non-throwing function, and `throws(Error)` is equivalent to non-typed `throws`. These redundant annotations add unnecessary complexity to function signatures.

  ```swift
  // WRONG
  func doSomething() throws(Never) -> Int {
    return 0
  }

  func doSomethingElse() throws(Error) -> Int {
    throw MyError.failed
  }

  // RIGHT
  func doSomething() -> Int {
    return 0
  }

  func doSomethingElse() throws -> Int {
    throw MyError.failed
  }
  ```

  </details>

### Closures

* <a id='favor-void-closure-return'></a>(<a href='#favor-void-closure-return'>link</a>) **Favor `Void` return types over `()` in closure declarations.** If you must specify a `Void` return type in a function declaration, use `Void` rather than `()` to improve readability. [![SwiftFormat: void](https://img.shields.io/badge/SwiftFormat-void-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#void)

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

* <a id='unused-closure-parameter-naming'></a>(<a href='#unused-closure-parameter-naming'>link</a>) **Name unused closure parameters as underscores (`_`).** [![SwiftFormat: unusedArguments](https://img.shields.io/badge/SwiftFormat-unusedArguments-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#unusedArguments)

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

* <a id='closure-brace-spacing'></a>(<a href='#closure-brace-spacing'>link</a>) **Closures should have a single space or newline inside each brace.** Trailing closures should additionally have a single space or newline outside each brace. [![SwiftFormat: spaceInsideBraces](https://img.shields.io/badge/SwiftFormat-spaceInsideBraces-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#spaceInsideBraces) [![SwiftFormat: spaceAroundBraces](https://img.shields.io/badge/SwiftFormat-spaceAroundBraces-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#spaceAroundBraces)

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

* <a id='omit-closure-void-return'></a>(<a href='#omit-closure-void-return'>link</a>) **Omit `Void` return types from closure expressions.** [![SwiftFormat: redundantVoidReturnType](https://img.shields.io/badge/SwiftFormat-redundantVoidReturnType-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#redundantVoidReturnType)

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

* <a id='anonymous-trailing-closures'></a>(<a href='#anonymous-trailing-closures'>link</a>) **Prefer trailing closure syntax for closure arguments with no parameter name.** [![SwiftFormat: trailingClosures](https://img.shields.io/badge/SwiftFormat-trailingClosures-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#trailingClosures)

  <details>

  ```swift
  // WRONG
  planets.map({ $0.name })

  // RIGHT
  planets.map { $0.name }

  // ALSO RIGHT, since this closure has a parameter name
  planets.first(where: { $0.isGasGiant })

  // ALSO FINE. Trailing closure syntax is still permitted for closures
  // with parameter names. However, consider using non-trailing syntax
  // in cases where the parameter name is semantically meaningful.
  planets.first { $0.isGasGiant }
  ```

  </details>

* <a id='unowned-captures'></a>(<a href='#unowned-captures'>link</a>) **Avoid using `unowned` captures.** Instead prefer safer alternatives like `weak` captures, or capturing variables directly. [![SwiftLint: unowned_variable_capture](https://img.shields.io/badge/SwiftLint-unowned__variable__capture-007A87.svg)](https://realm.github.io/SwiftLint/unowned_variable_capture.html)

  <details>
  `unowned` captures are unsafe because they will cause the application to crash if the referenced object has been deallocated.

  ```swift
  // WRONG: Crashes if `self` has been deallocated when closures are called.
  final class SpaceshipNavigationService {
    let spaceship: Spaceship
    let planet: Planet
    
    func colonizePlanet() {
      spaceship.travel(to: planet, onArrival: { [unowned self] in
        planet.colonize()
      })
    }
    
    func exploreSystem() {
      spaceship.travel(to: planet, nextDestination: { [unowned self] in
        planet.moons?.first
      })
    }
  }
  ```

  `weak` captures are safer because they require the author to explicitly handle the case where the referenced object no longer exists.

  ```swift
  // RIGHT: Uses a `weak self` capture and explicitly handles the case where `self` has been deallocated
  final class SpaceshipNavigationService {
    let spaceship: Spaceship
    let planet: Planet
    
    func colonizePlanet() {
      spaceship.travel(to: planet, onArrival: { [weak self] in
          guard let self else { return }
          planet.colonize()
        }
      )
    }
    
    func exploreSystem() {
      spaceship.travel(to: planet, nextDestination: { [weak self] in
          guard let self else { return nil }
          return planet.moons?.first
        }
      )
    }
  }
  ```

  Alternatively, consider directly capturing the variables that are used in the closure. This lets you avoid having to handle the case where `self` is nil, since you don't even need to reference `self`:

  ```swift
  // RIGHT: Explicitly captures `planet` instead of capturing `self`
  final class SpaceshipNavigationService {
    let spaceship: Spaceship
    let planet: Planet
    
    func colonizePlanet() {
      spaceship.travel(to: planet, onArrival: { [planet] in
          planet.colonize()
        }
      )
    }
    
    func exploreSystem() {
      spaceship.travel(to: planet, nextDestination: { [planet] in
          planet.moons?.first
        }
      )
    }
  }
  ```
  
  </details>

### Operators

* <a id='infix-operator-spacing'></a>(<a href='#infix-operator-spacing'>link</a>) **Infix operators should have a single space on either side.** However, in operator definitions, omit the trailing space between the operator and the open parenthesis. This rule does not apply to range operators (e.g. `1...3`). [![SwiftFormat: spaceAroundOperators](https://img.shields.io/badge/SwiftFormat-spaceAroundOperators-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#spacearoundoperators)

  <details>

  ```swift
  // WRONG
  let capacity = 1+2
  let capacity = currentCapacity??0
  let capacity=newCapacity
  let latitude = region.center.latitude-region.span.latitudeDelta/2.0

  // RIGHT
  let capacity = 1 + 2
  let capacity = currentCapacity ?? 0
  let capacity = newCapacity
  let latitude = region.center.latitude - region.span.latitudeDelta / 2.0
  ```

  ```swift
  // WRONG
  static func == (_ lhs: MyView, _ rhs: MyView) -> Bool {
    lhs.id == rhs.id
  }

  // RIGHT
  static func ==(_ lhs: MyView, _ rhs: MyView) -> Bool {
    lhs.id == rhs.id
  }
  ```

  </details>

* <a id='long-ternary-operator-expressions'></a>(<a href='#long-ternary-operator-expressions'>link</a>) **[Long](https://github.com/airbnb/swift#column-width) ternary operator expressions should wrap before the `?` and before the `:`**, putting each conditional branch on a separate line. [![SwiftFormat: wrap](https://img.shields.io/badge/SwiftFormat-wrap-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#wrap)

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

* <a id='use-commas-in-and-conditions'></a>(<a href='#use-commas-in-and-conditions'>link</a>) In conditional statements (`if`, `guard`, `while`), separate boolean conditions using commas (`,`) instead of `&&` operators.  [![SwiftFormat: andOperator](https://img.shields.io/badge/SwiftFormat-andOperator-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#andOperator)

  <details>

  ```swift
  // WRONG
  if let star = planet.star, !planet.isHabitable && planet.isInHabitableZone(of: star) {
    planet.terraform()
  }

  if
    let star = planet.star,
    !planet.isHabitable
    && planet.isInHabitableZone(of: star)
  {
    planet.terraform()
  }

  // RIGHT
  if let star = planet.star, !planet.isHabitable, planet.isInHabitableZone(of: star) {
    planet.terraform()
  }

  if
    let star = planet.star,
    !planet.isHabitable,
    planet.isInHabitableZone(of: star)
  {
    planet.terraform()
  }
  ```

  </details>

* <a id='prefer-bound-generic-extension-shorthand'></a>(<a href='#prefer-bound-generic-extension-shorthand'>link</a>) When extending bound generic types, prefer using generic bracket syntax (`extension Collection<Planet>`), or sugared syntax for applicable standard library types (`extension [Planet]`) instead of generic type constraints. [![SwiftFormat: genericExtensions](https://img.shields.io/badge/SwiftFormat-genericExtensions-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#genericExtensions)

  <details>

  ```swift
  // WRONG
  extension Array where Element == Star { … }
  extension Optional where Wrapped == Spaceship { … }
  extension Dictionary where Key == Moon, Element == Planet { … }
  extension Collection where Element == Universe { … }
  extension StateStore where State == SpaceshipState, Action == SpaceshipAction { … }

  // RIGHT
  extension [Star] { … }
  extension Spaceship? { … }
  extension [Moon: Planet] { … }
  extension Collection<Universe> { … }
  extension StateStore<SpaceshipState, SpaceshipAction> { … }

  // ALSO RIGHT. There are multiple types that could satisfy this constraint
  // (e.g. [Planet], [Moon]), so this is not a "bound generic type" and isn't
  // eligible for the generic bracket syntax.
  extension Array where Element: PlanetaryBody { }
  ```

  </details>

* <a id='no-semicolons'></a>(<a href='#no-semicolons'>link</a>) **Avoid using semicolons.** Semicolons are not required at the end of a line, so should be omitted. While you can use semicolons to place two statements on the same line, it is more common and preferred to separate them using a newline instead. [![SwiftFormat: semicolons](https://img.shields.io/badge/SwiftFormat-semicolons-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#semicolons)

  <details>

  ### Examples

  ```swift
  // WRONG. Semicolons are not required and can be omitted.
  let mercury = planets[0];
  let venus = planets[1];
  let earth = planets[2];

  // WRONG. While you can use semicolons to place multiple statements on a single line,
  // it is more common and preferred to separate them using newlines instead.
  let mercury = planets[0]; let venus = planets[1]; let earth = planets[2];

  // RIGHT
  let mercury = planets[0]
  let venus = planets[1]
  let earth = planets[2]

  // WRONG
  guard let moon = planet.moon else { completion(nil); return }

  // WRONG
  guard let moon = planet.moon else { 
    completion(nil); return
  }

  // RIGHT
  guard let moon = planet.moon else { 
    completion(nil)
    return
  }
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

* <a id='omit-redundant-memberwise-init'></a>(<a href='#omit-redundant-memberwise-init'>link</a>) **Omit redundant memberwise initializers.** The compiler can synthesize memberwise initializers for structs, so explicit initializers that only assign parameters to properties with the same names should be omitted. Note that this only applies to `internal`, `fileprivate` and `private` initializers, since compiler-synthesized memberwise initializers are only generated for those access controls. [![SwiftFormat: redundantMemberwiseInit](https://img.shields.io/badge/SwiftFormat-redundantMemberwiseInit-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#redundantMemberwiseInit)

  <details>

  #### Why?
  Removing redundant memberwise initializers reduces boilerplate and makes the code more concise. The compiler-synthesized initializers are equivalent to the explicit ones, so there's no functional difference.

  ```swift
  // WRONG
  struct Planet {
    let name: String
    let mass: Double
    let radius: Double

    init(name: String, mass: Double, radius: Double) {
      self.name = name
      self.mass = mass
      self.radius = radius
    }
  }

  // RIGHT
  struct Planet {
    let name: String
    let mass: Double
    let radius: Double
  }

  // ALSO RIGHT: Custom logic in initializer makes it non-redundant
  struct Planet {
    let name: String
    let mass: Double
    let radius: Double

    init(name: String, mass: Double, radius: Double) {
      self.name = name.capitalized
      self.mass = max(0, mass)
      self.radius = max(0, radius)
    }
  }

  // ALSO RIGHT: Public initializer is not redundant since compiler-synthesized 
  // memberwise initializers are always internal
  public struct Planet {
    public let name: String
    public let mass: Double
    public let radius: Double

    public init(name: String, mass: Double, radius: Double) {
      self.name = name
      self.mass = mass
      self.radius = radius
    }
  }
  ```

  </details>

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
  // WRONG
  class MyClass {

    func request(completion: () -> Void) {
      API.request() { [weak self] response in
        if let self {
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
        guard let self else { return }
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

* <a id='modifier-order'></a>(<a href='#modifier-order'>link</a>) **Use consistent ordering for modifiers.** Access modifiers like `public` and `private` come before other modifiers like `final` or `static`. [![SwiftFormat: modifierOrder](https://img.shields.io/badge/SwiftFormat-modifierOrder-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#modifierOrder)

  <details>

  ```swift
  // WRONG
  final public class Spaceship {}
  ```

  ```swift
  // RIGHT
  public final class Spaceship {}
  ```

  </details>

* <a id='limit-access-control'></a>(<a href='#limit-access-control'>link</a>) **Access control should be at the strictest level possible.** Prefer `public` to `open` and `private` to `fileprivate` unless you need that behavior. [![SwiftFormat: redundantFileprivate](https://img.shields.io/badge/SwiftFormat-redundantFileprivate-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#redundantFileprivate)

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
  func age(of person: Person, bornAt: TimeInterval) -> Int {
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

* <a id='namespace-using-enums'></a>(<a href='#namespace-using-enums'>link</a>) **Use caseless `enum`s for organizing `public` or `internal` constants and functions into namespaces.** [![SwiftFormat: enumNamespaces](https://img.shields.io/badge/SwiftFormat-enumNamespaces-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#enumNamespaces)
  * Avoid creating non-namespaced global constants and functions.
  * Feel free to nest namespaces where it adds clarity.
  * `private` globals are permitted, since they are scoped to a single file and do not pollute the global namespace. Consider placing private globals in an `enum` namespace to match the guidelines for other declaration types.

  <details>

  #### Why?
  Caseless `enum`s work well as namespaces because they cannot be instantiated, which matches their intent.

  ```swift
  // WRONG
  struct Environment {
    static let earthGravity = 9.8
    static let moonGravity = 1.6
  }

  // WRONG
  struct Environment {

    struct Earth {
      static let gravity = 9.8
    }

    struct Moon {
      static let gravity = 1.6
    }
  }

  // RIGHT
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

* <a id='auto-enum-values'></a>(<a href='#auto-enum-values'>link</a>) **Use Swift's automatic enum values unless they map to an external source.** Add a comment explaining why explicit values are defined. [![SwiftFormat: redundantRawValues](https://img.shields.io/badge/SwiftFormat-redundantRawValues-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#redundantRawValues)

  <details>

  #### Why?
  To minimize user error, improve readability, and write code faster, rely on Swift's automatic enum values. If the value maps to an external source (e.g. it's coming from a network request) or is persisted across binaries, however, define the values explicitly, and document what these values are mapping to.

  This ensures that if someone adds a new value in the middle, they won't accidentally break things.

  ```swift
  // WRONG
  enum ErrorType: String {
    case error = "error"
    case warning = "warning"
  }

  // WRONG
  enum UserType: String {
    case owner
    case manager
    case member
  }

  // WRONG
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

  // WRONG
  enum ErrorCode: Int {
    case notEnoughMemory
    case invalidResource
    case timeOut
  }

  // RIGHT
  // Relying on Swift's automatic enum values
  enum ErrorType: String {
    case error
    case warning
  }

  // RIGHT
  /// These are written to a logging service. Explicit values ensure they're consistent across binaries.
  // swiftformat:disable redundantRawValues
  enum UserType: String {
    case owner = "owner"
    case manager = "manager"
    case member = "member"
  }
  // swiftformat:enable redundantRawValues

  // RIGHT
  // Relying on Swift's automatic enum values
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

  // RIGHT
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

* <a id='prefer-immutable-statics'></a>(<a href='#prefer-immutable-statics'>link</a>) **Prefer immutable or computed static properties over mutable ones whenever possible.** Use stored `static let` properties or computed `static var` properties over stored `static var` properties whenever possible, as stored `static var` properties are global mutable state.

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

* <a id='simplify-generic-constraints'></a>(<a href='#simplify-generic-constraints'>link</a>) **Prefer defining simple generic constraints in the generic parameter list rather than in the where clause.** [![SwiftFormat: simplifyGenericConstraints](https://img.shields.io/badge/SwiftFormat-simplifyGenericConstraints-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#simplifyGenericConstraints)

  <details>

  #### Why?
  Inline generic constraints (`<T: Protocol>`) are more concise and idiomatic than where clauses (`<T> where T: Protocol`) for simple protocol conformances. Using inline constraints for simple cases makes generic declarations easier to read at a glance. Where clauses are reserved for complex constraints that cannot be expressed inline, like associated type constraints (`T.Element == Star`) or concrete type equality.

  ```swift
  // WRONG
  struct SpaceshipDashboard<Left, Right>: View
    where Left: View, Right: View
  {
    ...
  }

  extension Spaceship {
    func fly<Destination>(
      to: Destination,
      didArrive: (Destination) -> Void
    ) where Destination: PlanetaryBody {
      ...
    }
  }

  // RIGHT
  struct SpaceshipDashboard<Left: View, Right: View>: View {
    ...
  }

  extension Spaceship {
    func fly<Destination: PlanetaryBody>(
      to: Destination,
      didArrive: (Destination) -> Void
    ) {
      ...
    }
  }

  // ALSO RIGHT: Complex constraints remain in where clause
  struct Galaxy<T: Collection> where T.Element == Star {}
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

* <a id='final-classes-by-default'></a>(<a href='#final-classes-by-default'>link</a>) **Default classes to `final`.** [![SwiftFormat: preferFinalClasses](https://img.shields.io/badge/SwiftFormat-preferFinalClasses-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#preferFinalClasses)

  <details>

  ```swift
  // WRONG
  public class SpacecraftEngine {
    // ...
  }

  // RIGHT
  public final class SpacecraftEngine {
    // ...
  }
  
  // ALSO RIGHT: Marked as `open`, explicitly intended to be subclassed.
  open class SpacecraftEngine {
    // ...
  }
  ```

  Most classes are never overridden, and composition is generally preferred over inheritance.
  
  If a class does need to be subclassed, use one of these approaches to indicate to the linter that the class should not be marked `final`:
  
  1. If the class is already `public`, mark the class as `open`. `open` access control indicates that the class is allowed to be subclassed:
  
  ```swift
  open class SpacecraftEngine {
    // ...
  }
  ```
  
  2. Include _"Base"_ in the class name to indicate that the class is a base class intended to be subclassed:
  
  ```swift
  class BaseSpacecraftEngine {
    // ...
  }
  ```
  
  3. Include a doc comment mentioning that the class is a base class intended to be subclassed:
  
  ```swift
  /// Base class for various spacecraft engine varieties
  class SpacecraftEngine {
    // ...
  }
  ```
  
  4. Implement the subclass in the same file as the base class:
  
  ```swift
  class SpacecraftEngine {
    // ...
  }
  
  #if DEBUG
  class MockSpacecraftEngine: SpacecraftEngine {
    // ...
  }
  #endif
  ```

  </details>

* <a id='switch-avoid-default'></a>(<a href='#switch-avoid-default'>link</a>) When switching over an enum, generally prefer enumerating all cases rather than using the `default` case.

  <details>

  #### Why?
  Enumerating every case requires developers and reviewers have to consider the correctness of every switch statement when new cases are added in the future.

  ```swift
  // NOT PREFERRED
  switch trafficLight {
  case .greenLight:
    // Move your vehicle
  default:
    // Stop your vehicle
  }

  // PREFERRED
  switch trafficLight {
  case .greenLight:
    // Move your vehicle
  case .yellowLight, .redLight:
    // Stop your vehicle
  }
  
  // COUNTEREXAMPLES

  enum TaskState {
    case pending
    case running
    case canceling
    case success(Success)
    case failure(Error)

    // We expect that this property will remain valid if additional cases are added to the enumeration.
    public var isRunning: Bool {
      switch self {
      case .running:
        true
      default:
        false
      }
    }  
  }

  extension TaskState: Equatable {
    // Explicitly listing each state would be too burdensome. Ideally this function could be implemented with a well-tested macro.
    public static func == (lhs: TaskState, rhs: TaskState) -> Bool {
      switch (lhs, rhs) {
      case (.pending, .pending):
        true
      case (.running, .running):
        true
      case (.canceling, .canceling):
        true
      case (.success(let lhs), .success(let rhs)):
        lhs == rhs
      case (.failure(let lhs), .failure(let rhs)):
        lhs == rhs
      default:
        false
      }
    }
  }
  ```

  </details>

* <a id='optional-nil-check'></a>(<a href='#optional-nil-check'>link</a>) **Check for nil rather than using optional binding if you don't need to use the value.** [![SwiftLint: unused_optional_binding](https://img.shields.io/badge/SwiftLint-unused__optional__binding-007A87.svg)](https://realm.github.io/SwiftLint/unused_optional_binding)

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

* <a id='omit-return'></a>(<a href='#omit-return'>link</a>) **Omit the `return` keyword when not required by the language.** [![SwiftFormat: redundantReturn](https://img.shields.io/badge/SwiftFormat-redundantReturn-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#redundantReturn)

  <details>

  ```swift
  // WRONG
  ["1", "2", "3"].compactMap { return Int($0) }

  var size: CGSize {
    return CGSize(
      width: 100.0,
      height: 100.0
    )
  }

  func makeInfoAlert(message: String) -> UIAlertController {
    return UIAlertController(
      title: "ℹ️ Info",
      message: message,
      preferredStyle: .alert
    )
  }

  var alertTitle: String {
    if issue.severity == .critical {
      return "💥 Critical Error"
    } else {
      return "ℹ️ Info"
    }
  }

  func type(of planet: Planet) -> PlanetType {
    switch planet {
    case .mercury, .venus, .earth, .mars:
      return .terrestrial
    case .jupiter, .saturn, .uranus, .neptune:
      return .gasGiant
    }
  }

  // RIGHT
  ["1", "2", "3"].compactMap { Int($0) }

  var size: CGSize {
    CGSize(
      width: 100.0,
      height: 100.0
    )
  }

  func makeInfoAlert(message: String) -> UIAlertController {
    UIAlertController(
      title: "ℹ️ Info",
      message: message,
      preferredStyle: .alert
    )
  }

  var alertTitle: String {
    if issue.severity == .critical {
      "💥 Critical Error"
    } else {
      "ℹ️ Info"
    }
  }

  func type(of planet: Planet) -> PlanetType {
    switch planet {
    case .mercury, .venus, .earth, .mars:
      .terrestrial
    case .jupiter, .saturn, .uranus, .neptune:
      .gasGiant
    }
  }
  ```

  </details>

* <a id='use-anyobject'></a>(<a href='#use-anyobject'>link</a>) **Use `AnyObject` instead of `class` in protocol definitions.** [![SwiftFormat: anyObjectProtocol](https://img.shields.io/badge/SwiftFormat-anyObjectProtocol-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#anyobjectprotocol)

  <details>

  #### Why?

  [SE-0156](https://github.com/apple/swift-evolution/blob/master/proposals/0156-subclass-existentials.md), which introduced support for using the `AnyObject` keyword as a protocol constraint, recommends preferring `AnyObject` over `class`:

  > This proposal merges the concepts of `class` and `AnyObject`, which now have the same meaning: they represent an existential for classes. To get rid of the duplication, we suggest only keeping `AnyObject` around. To reduce source-breakage to a minimum, `class` could be redefined as `typealias class = AnyObject` and give a deprecation warning on class for the first version of Swift this proposal is implemented in. Later, `class` could be removed in a subsequent version of Swift.

  ```swift
  // WRONG
  protocol Foo: class { }

  // RIGHT
  protocol Foo: AnyObject { }
  ```

  </details>

* <a id='extension-access-control'></a>(<a href='#extension-access-control'>link</a>) **Specify the access control for each declaration in an extension individually.** [![SwiftFormat: extensionAccessControl](https://img.shields.io/badge/SwiftFormat-extensionAccessControl-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#extensionaccesscontrol)

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

* <a id='no-file-literal'></a>(<a href='#no-file-literal'>link</a>) **Don't use `#file`. Use `#fileID` or `#filePath` as appropriate.**

  <details>

  #### Why?
  The behavior of the `#file` literal (or macro as of Swift 5.9) has evolved from evaluating to the full source file path (the behavior as of `#filePath`) to a human-readable string containing module and file name (the behavior of `#fileID`). Use the literal (or macro) with the most appropriate behavior for your use case.

  [Swift documentation](https://developer.apple.com/documentation/swift/file)

  [Swift Evolution Proposal: Concise magic file names](https://github.com/apple/swift-evolution/blob/main/proposals/0274-magic-file.md)

  </details>

* <a id='no-filepath-literal'></a>(<a href='#no-filepath-literal'>link</a>) **Don't use `#filePath` in production code. Use `#fileID` instead.**

  <details>

  #### Why?
  `#filePath` should only be used in non-production code where the full path of the source file provides useful information to developers. Because `#fileID` doesn’t embed the full path to the source file, it won't expose your file system and reduces the size of the compiled binary.

  [#filePath documentation](https://developer.apple.com/documentation/swift/filepath#overview)

  </details>

* <a id='avoid-redundant-closures'></a>(<a href='#avoid-redundant-closures'>link</a>) **Avoid single-expression closures that are always called immediately**. Instead, prefer inlining the expression. [![SwiftFormat: redundantClosure](https://img.shields.io/badge/SwiftFormat-redundantClosure-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#redundantClosure)

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
      withAverageDistance: 4
    )
  }()

  // RIGHT
  lazy var universe = Universe()

  lazy var stars = universe.generateStars(
    at: location,
    count: 5,
    color: starColor,
    withAverageDistance: 4
  )
  ```

  </details>

* <a id='redundant-get'></a>(<a href='#redundant-get'>link</a>) **Omit the `get` clause from a computed property declaration that doesn't also have a `set`, `willSet`, or `didSet` clause.** [![SwiftFormat: redundantGet](https://img.shields.io/badge/SwiftFormat-redundantGet-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#redundantGet)

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

* <a id='prefer-opaque-generic-parameters'></a>(<a href='#prefer-opaque-generic-parameters'>link</a>) **Prefer using opaque generic parameters (with `some`) over verbose named generic parameter syntax where possible.**  [![SwiftFormat: opaqueGenericParameters](https://img.shields.io/badge/SwiftFormat-opaqueGenericParameters-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#opaqueGenericParameters)

    <details>

    #### Why?

    Opaque generic parameter syntax is significantly less verbose and thus more legible than the full named generic parameter syntax.

    ```swift
    // WRONG
    func spaceshipDashboard<WarpDriveView: View, CaptainsLogView: View>(
      warpDrive: WarpDriveView,
      captainsLog: CaptainsLogView
    ) -> some View {
      …
    }

    func generate<Planets>(_ planets: Planets) where Planets: Collection, Planets.Element == Planet {
      …
    }

    // RIGHT
    func spaceshipDashboard(
      warpDrive: some View,
      captainsLog: some View
    ) -> some View {
      …
    }

    func generate(_ planets: some Collection<Planet>) {
      …
    }

    // Also fine, since there isn't an equivalent opaque parameter syntax for expressing
    // that two parameters in the type signature are of the same type:
    func terraform<Body: PlanetaryBody>(_ planetaryBody: Body, into terraformedBody: Body) {
      …
    }

    // Also fine, since the generic parameter name is referenced in the function body so can't be removed:
    func terraform<Body: PlanetaryBody>(_ planetaryBody: Body) {
      planetaryBody.generateAtmosphere(Body.idealAtmosphere)
    }
    ```

    #### `some Any`

    Fully-unconstrained generic parameters are somewhat uncommon, but are equivalent to `some Any`. For example:

    ```swift
    func assertFailure<Value>(
      _ result: Result<Value, Error>,
      file: StaticString = #filePath,
      line: UInt = #line
    ) {
      if case .failure(let error) = result {
        XCTFail(error.localizedDescription, file: file, line: line)
      }
    }

    // is equivalent to:
    func assertFailure(
      _ result: Result<some Any, Error>,
      file: StaticString = #filePath,
      line: UInt = #line
    ) {
      if case .failure(let error) = result {
        XCTFail(error.localizedDescription, file: file, line: line)
      }
    }
    ```

    `some Any` is somewhat unintuitive, and the named generic parameter is useful in this situation to compensate for the weak type information. Because of this, prefer using named generic parameters instead of `some Any`.

    </details>

* <a id='unchecked-sendable'></a>(<a href='#unchecked-sendable'>link</a>) **Prefer to avoid using `@unchecked Sendable`**. Use a standard `Sendable` conformance instead where possible. If working with a type from a module that has not yet been updated to support Swift Concurrency, suppress concurrency-related errors using `@preconcurrency import`. 

    <details>

    `@unchecked Sendable` provides no guarantees about the thread safety of a type, and instead unsafely suppresses compiler errors related to concurrency checking. 

    There are typically other, safer methods for suppressing concurrency-related errors:

    ### 1. Use `Sendable` instead of `@unchecked Sendable`, with `@MainActor` if appropriate

    A `Sendable` conformance is the preferred way to declare that a type is thread-safe. The compiler will emit an error if a type conforming to `Sendable` is not thread-safe. For example, simple value types and immutable classes can always safely conform to `Sendable`, but mutable classes cannot:

    ```swift
    // RIGHT: Simple value types are thread-safe.
    struct Planet: Sendable {
      var mass: Double
    }

    // RIGHT: Immutable classes are thread-safe.
    final class Planet: Sendable {
      let mass: Double
    }

    // WRONG: Mutable classes are not thread-safe.
    final class Planet: Sendable {
      // ERROR: stored property 'mass' of 'Sendable'-conforming class 'Planet' is mutable
      var mass: Double
    }

    // WRONG: @unchecked is unnecessary because the compiler can prove that the type is thread-safe.
    struct Planet: @unchecked Sendable {
      var mass: Double
    }
    ```

    Mutable classes can be made `Sendable` and thread-safe if they are isolated to a single actor / thread / concurrency domain. Any mutable class can be made `Sendable` by isolating it to a global actor using an annotation like `@MainActor` (which isolates it to the main actor):

    ```swift
    // RIGHT: A mutable class isolated to the main actor is thread-safe.
    @MainActor
    final class Planet: Sendable {
      var mass: Double
    }

    // WRONG: @unchecked Sendable is unsafe because mutable classes are not thread-safe.
    struct Planet: @unchecked Sendable {
      var mass: Double
    }
    ```

    ### 2. Use `@preconcurrency import`

    If working with a non-`Sendable` type from a module that hasn't yet adopted Swift concurrency, suppress concurrency-related errors using `@preconcurrency import`.

    ```swift
    /// Defined in `UniverseKit` module
    class Planet: PlanetaryBody { 
      var star: Star
    }
    ```

    ```swift 
    // WRONG: Unsafely marking a non-thread-safe class as Sendable only to suppress errors
    import PlanetaryBody

    extension PlanetaryBody: @unchecked Sendable { }

    // RIGHT
    @preconcurrency import PlanetaryBody
    ```

    ### 3. Restructure code so the compiler can verify that it is thread-safe

    If possible, restructure code so that the compiler can verify that it is thread safe. This lets you use a `Sendable` conformance instead of an unsafe `@unchecked Sendable` conformance. 

    When conforming to `Sendable`, the compiler will emit an error in the future if you attempt to make a change that is not thread-safe. This guarantee is lost when using `@unchecked Sendable`, which makes it easier to accidentally introduce changes which are not thread-safe.

    For example, given this set of classes:

    ```swift
    class PlanetaryBody { 
      let mass: Double  
    }

    class Planet: PlanetaryBody { 
      let star: Star
    }

    // NOT IDEAL: no compiler-enforced thread safety.
    extension PlanetaryBody: @unchecked Sendable { }
    ```

    the compiler can't verify `PlanetaryBody` is `Sendable` because it is not `final`. Instead of using `@unchecked Sendable`, you could restructure the code to not use subclassing:

    ```swift
    // BETTER: Compiler-enforced thread safety.
    protocol PlanetaryBody: Sendable {
      var mass: Double { get }
    }

    final class Planet: PlanetaryBody, Sendable {
      let mass: Double
      let star: Star
    }
    ```

    ### Using `@unchecked Sendable` when necessary

    Sometimes it is truly necessary to use `@unchecked Sendable`. In these cases, you can add a `// swiftlint:disable:next no_unchecked_sendable` annotation with an explanation for how we know the type is thread-safe, and why we have to use `@unchecked Sendable` instead of `Sendable`.

    A canonical, safe use case of `@unchecked Sendable` is a class where the mutable state is protected by some other thread-safe mechanism like a lock. This type is thread-safe, but the compiler cannot verify this.

    ```swift
    struct Atomic<Value> {
      /// `value` is thread-safe because it is manually protected by a lock.
      var value: Value { ... }
    }

    // WRONG: disallowed by linter
    extension Atomic: @unchecked Sendable { }

    // WRONG: suppressing lint error without an explanation
    // swiftlint:disable:next no_unchecked_sendable
    extension Atomic: @unchecked Sendable { }

    // RIGHT: suppressing the linter with an explanation why the type is thread-safe
    // Atomic is thread-safe because its underlying mutable state is protected by a lock.
    // swiftlint:disable:next no_unchecked_sendable
    extension Atomic: @unchecked Sendable { }
    ```

    It is also reasonable to use `@unchecked Sendable` for types that are thread-safe in existing usage but can't be refactored to support a proper `Sendable` conformance (e.g. due to backwards compatibility constraints):

    ```swift
    class PlanetaryBody { 
      let mass: Double  
    }

    class Planet: PlanetaryBody { 
      let star: Star
    }

    // WRONG: disallowed by linter
    extension PlanetaryBody: @unchecked Sendable { }

    // WRONG: suppressing lint error without an explanation
    // swiftlint:disable:next no_unchecked_sendable
    extension PlanetaryBody: @unchecked Sendable { }

    // RIGHT: suppressing the linter with an explanation why the type is thread-safe
    // PlanetaryBody cannot conform to Sendable because it is non-final and has subclasses.
    // PlanetaryBody itself is safely Sendable because it only consists of immutable values.
    // All subclasses of PlanetaryBody are also simple immutable values, so are safely Sendable as well.
    // swiftlint:disable:next no_unchecked_sendable
    extension PlanetaryBody: @unchecked Sendable { }
    ```

    </details>

* <a id='redundant-property'></a>(<a href='#redundant-property'>link</a>) **Avoid defining properties that are then returned immediately.** Instead, return the value directly. [![SwiftFormat: redundantProperty](https://img.shields.io/badge/SwiftFormat-redundantProperty-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#redundantProperty)

    <details>

    ### Why?

    Property declarations that are immediately returned are typically redundant and unnecessary. Sometimes these are unintentionally created as the byproduct of refactoring. Cleaning them up automatically simplifies the code. In some cases this also results in the `return` keyword itself being unnecessary, further simplifying the code.

    ```swift
    // WRONG
    var spaceship: Spaceship {
      let spaceship = spaceshipBuilder.build(warpDrive: warpDriveBuilder.build())
      return spaceship
    }

    // RIGHT
    var spaceship: Spaceship {
      spaceshipBuilder.build(warpDrive: warpDriveBuilder.build())
    }

    // WRONG
    var spaceship: Spaceship {
      let warpDrive = warpDriveBuilder.build()
      let spaceship = spaceshipBuilder.build(warpDrive: warpDrive)
      return spaceship
    }

    // RIGHT
    var spaceship: Spaceship {
      let warpDrive = warpDriveBuilder.build()
      return spaceshipBuilder.build(warpDrive: warpDrive)
    }
    ```

    </details>

* <a id='redundant-equatable-implementation'></a>(<a href='#redundant-equatable-implementation'>link</a>) **Prefer using a generated Equatable implementation when comparing all properties of a type.** For structs, prefer using the compiler-synthesized Equatable implementation when possible. [![SwiftFormat: redundantEquatable](https://img.shields.io/badge/SwiftFormat-redundantEquatable-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#redundantEquatable)

    <details>

    ### Why?

    Manually-implemented Equatable implementations are verbose, and keeping them up-to-date is error-prone. For example, when adding a new property, it's possible to forget to update the Equatable implementation to compare it.

    ```swift
    /// WRONG: The `static func ==` implementation is redundant and error-prone.
    struct Planet: Equatable {
      let mass: Double
      let orbit: OrbitalElements
      let rotation: Double

      static func ==(lhs: Planet, rhs: Planet) -> Bool {
        lhs.mass == rhs.mass
          && lhs.orbit == rhs.orbit
          && lhs.rotation == rhs.rotation
      }
    }

    /// RIGHT: The `static func ==` implementation is synthesized by the compiler.
    struct Planet: Equatable {
      let mass: Double
      let orbit: OrbitalElements
      let rotation: Double
    }

    /// ALSO RIGHT: The `static func ==` implementation differs from the implementation that 
    /// would be synthesized by the compiler and compared all properties, so is not redundant.
    struct CelestialBody: Equatable {
      let id: UUID
      let orbit: OrbitalElements

      static func ==(lhs: Planet, rhs: Planet) -> Bool {
        lhs.id == rhs.id
      }
    }
    ```

    In projects that provide an `@Equatable` macro, prefer using that macro to generate the `static func ==` for classes rather than implementing it manually.

    ```swift
    /// WRONG: The `static func ==` implementation is verbose and error-prone.
    final class Planet: Equatable {
      let mass: Double
      let orbit: OrbitalElements
      let rotation: Double

      static func ==(lhs: Planet, rhs: Planet) -> Bool {
        lhs.mass == rhs.mass
          && lhs.orbit == rhs.orbit
          && lhs.rotation == rhs.rotation
      }
    }

    /// RIGHT: The `static func ==` implementation is generated by the `@Equatable` macro.
    @Equatable
    final class struct Planet: Equatable {
      let mass: Double
      let orbit: OrbitalElements
      let rotation: Double
    }
    ```

    </details>

* <a id='redundant-environment-key-implementation'></a>(<a href='#redundant-environment-key-implementation'>link</a>) **Prefer using the `@Entry` macro to define properties inside `EnvironmentValues`**. When adding properties to SwiftUI `EnvironmentValues`, prefer using the compiler-synthesized property implementation when possible. [![SwiftFormat: environmentEntry](https://img.shields.io/badge/SwiftFormat-environmentEntry-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/develop/Rules.md#environmentEntry)

    <details>

    ### Why?

    Manually-implemented environment keys are verbose and it is considered a legacy pattern. `@Entry` was specifically intended to be a replacement considering it was backported to iOS 13.

    ```swift
    /// WRONG: The `EnvironmentValues` property depends on `IsSelectedEnvironmentKey`
    struct IsSelectedEnvironmentKey: EnvironmentKey {
      static var defaultValue: Bool { false }
    }

    extension EnvironmentValues {
      var isSelected: Bool {
       get { self[IsSelectedEnvironmentKey.self] }
       set { self[IsSelectedEnvironmentKey.self] = newValue }
      }
    }

    /// RIGHT: The `EnvironmentValues` property uses the @Entry macro 
    extension EnvironmentValues {
      @Entry var isSelected: Bool = false
    }
    ```

    </details>

* <a id='void-type'></a>(<a href='#void-type'>link</a>) **Avoid using `()` as a type**. Prefer `Void`. [![SwiftFormat: void](https://img.shields.io/badge/SwiftFormat-void-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#void)

  <details>

  ```swift
  // WRONG
  let result: Result<(), Error>

  // RIGHT
  let result: Result<Void, Error>
  ```
  </details>

* <a id='void-instance'></a>(<a href='#void-instance'>link</a>) **Avoid using `Void()` as an instance of `Void`**. Prefer `()`. [![SwiftFormat: void](https://img.shields.io/badge/SwiftFormat-void-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#void)

  <details>

  ```swift
  let completion: (Result<Void, Error>) -> Void 

  // WRONG
  completion(.success(Void()))
  
  // RIGHT
  completion(.success(()))
  ```
  </details>

* <a id='count-where'></a>(<a href='#count-where'>link</a>) **Prefer using `count(where: { … })` over `filter { … }.count`**. [![SwiftFormat: preferCountWhere](https://img.shields.io/badge/SwiftFormat-preferCountWhere-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#preferCountWhere)

  <details>

  Swift 6.0 ([finally!](https://forums.swift.org/t/accepted-again-se-0220-count-where/66659)) added a `count(where:)` method to the standard library. Prefer using the `count(where:)` method over using the `filter(_:)` method followed by a `count` call.

  ```swift
  // WRONG
  let planetsWithMoons = planets.filter { !$0.moons.isEmpty }.count

  // RIGHT
  let planetsWithMoons = planets.count(where: { !$0.moons.isEmpty })
  ```
  </details>

* <a id='url-macro'></a>(<a href='#url-macro'>link</a>) **If available in your project, prefer using a `#URL(_:)` macro instead of force-unwrapping `URL(string:)!` initializer`**. [![SwiftFormat: urlMacro](https://img.shields.io/badge/SwiftFormat-urlMacro-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#urlMacro)

    <details>

    #### Why?

    The `#URL` macro provides compile-time validation of URL strings, eliminating runtime crashes from invalid URLs while maintaining clean syntax for static URL creation.

    ```swift
    // WRONG
    let url = URL(string: "https://example.com")!

    // RIGHT
    let url = #URL("https://example.com")
    ```
    </details>

**[⬆ back to top](#table-of-contents)**

## File Organization

* <a id='alphabetize-and-deduplicate-imports'></a>(<a href='#alphabetize-and-deduplicate-imports'>link</a>) **Alphabetize and deduplicate module imports within a file. Place all imports at the top of the file below the header comments. Do not add additional line breaks between import statements. Add a single empty line before the first import and after the last import.** [![SwiftFormat: sortedImports](https://img.shields.io/badge/SwiftFormat-sortedImports-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#sortedImports) [![SwiftFormat: duplicateImports](https://img.shields.io/badge/SwiftFormat-duplicateImports-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#duplicateImports)

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

  // RIGHT

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

  // RIGHT

  //  Copyright © 2018 Airbnb. All rights reserved.
  //

  import DLSPrimitives
  import Foundation
  import Nimble
  import Quick

  @testable import Epoxy
  ```

  </details>

* <a id='limit-consecutive-whitespace'></a><a id='limit-vertical-whitespace'></a>(<a href='#limit-consecutive-whitespace'>link</a>) **Limit consecutive whitespace to one blank line or space (excluding indentation).** Favor the following formatting guidelines over whitespace of varying heights or widths. [![SwiftFormat: consecutiveBlankLines](https://img.shields.io/badge/SwiftFormat-consecutiveBlankLines-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#consecutiveBlankLines) [![SwiftFormat: consecutiveSpaces](https://img.shields.io/badge/SwiftFormat-consecutiveSpaces-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#consecutiveSpaces)

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


* <a id='newline-at-eof'></a>(<a href='#newline-at-eof'>link</a>) **Files should end in a newline.** [![SwiftFormat: linebreakAtEndOfFile](https://img.shields.io/badge/SwiftFormat-linebreakAtEndOfFile-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#linebreakatendoffile)

* <a id='newline-between-scope-siblings'></a>(<a href='#newline-between-scope-siblings'>link</a>) **Declarations that include scopes spanning multiple lines should be separated from adjacent declarations in the same scope by a newline.** Insert a single blank line between multi-line scoped declarations (e.g. types, extensions, functions, computed properties, etc.) and other declarations at the same indentation level. [![SwiftFormat: blankLinesBetweenScopes](https://img.shields.io/badge/SwiftFormat-blankLinesBetweenScopes-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#blankLinesBetweenScopes)

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

* <a id='no-blank-lines-at-start-or-end-of-non-type-scopes'></a>(<a href='#no-blank-lines-at-start-or-end-of-non-type-scopes'>link</a>) **Remove blank lines at the top and bottom of scopes**, excluding type bodies which can optionally include blank lines. [![SwiftFormat: blankLinesAtStartOfScope](https://img.shields.io/badge/SwiftFormat-blankLinesAtStartOfScope-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#blankLinesAtStartOfScope) [![SwiftFormat: blankLinesAtEndOfScope](https://img.shields.io/badge/SwiftFormat-blankLinesAtEndOfScope-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#blankLinesAtEndOfScope)

  <details>

  ```swift
  // WRONG
  class Planet {
    func terraform() {

      generateAtmosphere()
      generateOceans()

    }
  }

  // RIGHT
  class Planet {
    func terraform() {
      generateAtmosphere()
      generateOceans()
    }
  }

  // Also fine!
  class Planet {

    func terraform() {
      generateAtmosphere()
      generateOceans()
    }

  }
  ```

  </details>


* <a id='mark-types-and-extensions'></a>(<a href='#mark-types-and-extensions'>link</a>) **Each type and extension which implements a conformance should be preceded by a `MARK` comment.** [![SwiftFormat: markTypes](https://img.shields.io/badge/SwiftFormat-markTypes-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#markTypes)
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

* <a id='marks-within-types'></a>(<a href='#marks-within-types'>link</a>) **Use `// MARK:` to separate the contents of type definitions and extensions into the sections listed below, in order.** All type definitions and extensions should be divided up in this consistent way, allowing a reader of your code to easily jump to what they are interested in. [![SwiftFormat: organizeDeclarations](https://img.shields.io/badge/SwiftFormat-organizeDeclarations-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#organizeDeclarations)
  * `// MARK: Lifecycle` for `init` and `deinit` methods.
  * `// MARK: Open` for `open` properties and methods.
  * `// MARK: Public` for `public` properties and methods.
  * `// MARK: Package` for `package` properties and methods.
  * `// MARK: Internal` for `internal` properties and methods.
  * `// MARK: Fileprivate` for `fileprivate` properties and methods.
  * `// MARK: Private` for `private` properties and methods.
  * If the type in question is an enum, its cases should go above the first `// MARK:`.
  * Do not subdivide each of these sections into subsections, as it makes the method dropdown more cluttered and therefore less useful. Instead, group methods by functionality and use smart naming to make clear which methods are related. If there are enough methods that sub-sections seem necessary, consider refactoring your code into multiple types.
  * If all of the type or extension's definitions belong to the same category (e.g. the type or extension only consists of `internal` properties), it is OK to omit the `// MARK:`s.
  * If the type in question is a simple value type (e.g. fewer than 20 lines), it is OK to omit the `// MARK:`s, as it would hurt legibility.

* <a id='subsection-organization'></a>(<a href='#subsection-organization'>link</a>) **Within each top-level section, place content in the following order.** This allows a new reader of your code to more easily find what they are looking for. [![SwiftFormat: organizeDeclarations](https://img.shields.io/badge/SwiftFormat-organizeDeclarations-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#organizeDeclarations)
  * Nested types and type aliases
  * Static properties
  * Static property with body
  * Class properties with body
  * SwiftUI dynamic properties (@State, @Environment, @Binding, etc), grouped by type
  * Instance properties
  * Instance properties with body
  * Static methods
  * Class methods
  * Instance methods

  <details>
  
    Computed properties and properties with property observers should appear at the end of the set of declarations of the same kind. (e.g. instance properties.)

    ```swift
    // WRONG
    class PlanetView: UIView {
    
      static var startOfTime { -CGFloat.greatestFiniteMagnitude / 0 }

      var atmosphere: Atmosphere {
         didSet {
           print("oh my god, the atmosphere changed")
         }
       }

      override class var layerClass: AnyClass {
        PlanetLayer.self
      }

      var gravity: CGFloat

      static let speedOfLight: CGFloat = 300_000
    }

    // RIGHT
    class PlanetView: UIView {
    
      static let speedOfLight: CGFloat = 300_000
      static var startOfTime { -CGFloat.greatestFiniteMagnitude / 0 }

      override class var layerClass: AnyClass {
        PlanetLayer.self
      }

      var gravity: CGFloat
      var atmosphere: Atmosphere {
         didSet {
           print("oh my god, the atmosphere changed")
         }
       }
    }
    ```

    SwiftUI Properties are a special type of property that lives inside SwiftUI views. These views conform to the [`DynamicProperty`](https://developer.apple.com/documentation/swiftui/dynamicproperty) protocol and cause the view's body to re-compute. Given this common functionality and also a similar syntax, it is preferred to group them.

    ```swift
    // WRONG

    struct CustomSlider: View {
    
      // MARK: Internal

      var body: some View {
        ...
      }

      // MARK: Private

      @Binding private var value: Value
      private let range: ClosedRange<Double>
      @Environment(\.sliderStyle) private var style
      private let step: Double.Stride
      @Environment(\.layoutDirection) private var layoutDirection
    }

    // RIGHT

    struct CustomSlider: View {
      
      // MARK: Internal

      var body: some View {
        ...
      }

      // MARK: Private

      @Environment(\.sliderStyle) private var style
      @Environment(\.layoutDirection) private var layoutDirection
      @Binding private var value: Value

      private let range: ClosedRange<Double>
      private let step: Double.Stride
    }
    ```

    Additionally, within the grouping of SwiftUI properties, it is preferred that the properties are also grouped by their dynamic property type. The group order applied by the formatter is determined by the first time a type appears:

    ```swift
    // WRONG
    struct CustomSlider: View {

      @Binding private var value: Value
      @State private var foo = Foo()
      @Environment(\.sliderStyle) private var style
      @State private var bar = Bar()
      @Environment(\.layoutDirection) private var layoutDirection

      private let range: ClosedRange<Double>
      private let step: Double.Stride
    }

    // RIGHT
    struct CustomSlider: View {

      @Binding private var value: Value
      @State private var foo = Foo()
      @State private var bar = Bar()
      @Environment(\.sliderStyle) private var style
      @Environment(\.layoutDirection) private var layoutDirection

      private let range: ClosedRange<Double>
      private let step: Double.Stride
    }
    ```

  </details>


* <a id='newline-between-subsections'></a>(<a href='#newline-between-subsections'>link</a>) **Add empty lines between property declarations of different kinds.** (e.g. between static properties and instance properties.) [![SwiftFormat: organizeDeclarations](https://img.shields.io/badge/SwiftFormat-organizeDeclarations-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#organizeDeclarations)

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

* <a id='single-propery-per-line'></a>(<a href='#single-propery-per-line'>link</a>) **Only define a single property or enum case per line.** [![SwiftFormat: singlePropertyPerLine](https://img.shields.io/badge/SwiftFormat-singlePropertyPerLine-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#singlePropertyPerLine) [![SwiftFormat: wrapEnumCases](https://img.shields.io/badge/SwiftFormat-wrapEnumCases-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#wrapEnumCases)

  <details>

  #### Why?
   - Declarations that define a single property are much more common, and more idiomatic.
   - Only using the standard form of property declarations makes it easier to write and maintain tools that operate on source code, like macros, lint rules, and code autocorrect.

  ```swift
  // WRONG
  let mercury, venus: Planet

  let earth = planets[2], mars = planets[3]

  let (jupiter, saturn) = (planets[4], planets[5])

  enum IceGiants {
    case neptune, uranus
  }

  // RIGHT
  let mercury: Planet
  let venus: Planet

  let earth = planets[2]
  let mars = planets[3]

  let jupiter = planets[4]
  let saturn = planets[5]

  enum IceGiants {
    case neptune
    case uranus
  }
  
  // ALSO RIGHT: Tuple destructing is fine for values like function call results.
  let (ceres, pluto) = findAndClassifyDwarfPlanets()
  ```

  </details>
  
* <a id='remove-empty-extensions'></a>(<a href='#remove-empty-extensions'>link</a>) **Remove empty extensions that define no properties, functions, or conformances.** [![SwiftFormat: emptyExtensions](https://img.shields.io/badge/SwiftFormat-emptyExtensions-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#emptyExtensions)

  <details>

  #### Why?
  Improves readability since the code has no effect and should be removed for clarity.
  
  ```swift
  // WRONG: The first extension is empty and redundant.
  extension Planet {}
  
  extension Planet: Equatable {}

  // RIGHT: Empty extensions that add a protocol conformance aren't redundant.
  extension Planet: Equatable {}
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
        forControlEvents: .touchUpInside
      )
    }

    @objc
    private func didTapAcceptButton() {
      // ...
    }
  }
  ```

  </details>

**[⬆ back to top](#table-of-contents)**

## Testing

* <a id='swift-testing-test-case-names'></a>(<a href='#swift-testing-test-case-names'>link</a>) **In Swift Testing, don't prefix test case methods with "`test`".** [![SwiftFormat: swiftTestingTestCaseNames](https://img.shields.io/badge/SwiftFormat-swiftTestingTestCaseNames-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#swiftTestingTestCaseNames)

  <details>

  ### Why?

  Prefixing test case methods with "`test`" was necessary with XCTest, but is not necessary in Swift Testing. [Idiomatic usage](https://developer.apple.com/documentation/testing/migratingfromxctest#Convert-test-methods) of Swift Testing excludes the "`test`" prefix.

  ```swift
  import Testing
  
  /// WRONG
  struct SpaceshipTests {
    @Test
    func testWarpDriveEnablesFTLTravel() { ... }

    @Test
    func testArtificialGravityMatchesEarthGravity() { ... }
  }

  /// RIGHT
  struct SpaceshipTests {
    @Test
    func warpDriveEnablesFTLTravel() { ... }

    @Test
    func artificialGravityMatchesEarthGravity() { ... }
  }
  ```
  </details>

* <a id='avoid-guard-in-tests'></a>(<a href='#avoid-guard-in-tests'>link</a>) **Avoid `guard` statements in unit tests**. XCTest and Swift Testing have APIs for unwrapping an optional and failing the test, which are much simpler than unwrapping the optionals yourself. Use assertions instead of guarding on boolean conditions. [![SwiftFormat: noGuardInTests](https://img.shields.io/badge/SwiftFormat-noGuardInTests-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#noGuardInTests)

  <details>

  ```swift
  import XCTest

  final class SomeTestCase: XCTestCase {
    func test_something() throws {
      // WRONG:
      guard let value = optionalValue, value.matchesCondition else {
        XCTFail()
        return
      }

      // RIGHT:
      let value = try XCTUnwrap(optionalValue)
      XCTAssert(value.matchesCondition)
    }
  }
  ```

  ```swift
  import Testing

  struct SomeTests {
    @Test
    func something() throws {
      // WRONG:
      guard let value = optionalValue, value.matchesCondition {
        return
      }

      // RIGHT:
      let value = try #require(optionalValue)
      #expect(value.matchesCondition)
    }
  }
  ```

* <a id='prefer-throwing-tests'></a>(<a href='#prefer-throwing-tests'>link</a>) **Prefer throwing tests to `try!`**. `try!` will crash your test suite like a force-unwrapped optional. XCTest and Swift Testing support throwing test methods, so use that instead. [![SwiftFormat: noForceTryInTests](https://img.shields.io/badge/SwiftFormat-noForceTryInTests-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#noForceTryInTests)

  <details>

  ```swift
  import XCTest

  final class SomeTestCase: XCTestCase {
    // WRONG
    func test_something() {
      try! Something().doSomething()
    }

    // RIGHT
    func test_something() throws {
      try Something().doSomething()
    }
  }
  ```

  ```swift
  import Testing

  struct SomeTests {
    // WRONG
    @Test
    func something() {
      try! Something().doSomething()
    }

    // RIGHT
    @Test
    func something() throws {
      try Something().doSomething()
    }
  }
  ```
  </details>

* <a id='test-suite-access-control'></a>(<a href='#test-suite-access-control'>link</a>) **In test suites, test cases should be `internal`, and helper methods and properties should be `private`**. [![SwiftFormat: testSuiteAccessControl](https://img.shields.io/badge/SwiftFormat-testSuiteAccessControl-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#testSuiteAccessControl)

  <details>

  #### Why?
  Test suites and test cases don't need to be `public` to be picked up by XCTest / Swift Testing, so should be `internal`.

  Helpers and stored properties should be `private` since they are not accessed outside of the test suite.

  ```swift
  import Testing

  // WRONG
  struct SpaceshipTests {
    let spaceship = Spaceship()

    func launchSpaceship() {
      spaceship.launch()
    }

    @Test
    func spaceshipCanLaunch() {
      launchSpaceship()
      #expect(spaceship.hasLaunched)
    }
  }

  // RIGHT
  struct SpaceshipTests {

    // MARK: Internal

    @Test
    func spaceshipCanLaunch() {
      launchSpaceship()
      #expect(spaceship.hasLaunched)
    }

    // MARK: Private

    private let spaceship = Spaceship()

    private func launchSpaceship() {
      spaceship.launch()
    }

  }
  ```

  ```swift
  import XCTest

  // WRONG
  final class SpaceshipTests: XCTestCase {
    let spaceship = Spaceship()

    func launchSpaceship() {
      spaceship.launch()
    }

    func testSpaceshipCanLaunch() {
      launchSpaceship()
      XCTAssertTrue(spaceship.hasLaunched)
    }
  }

  // RIGHT
  final class SpaceshipTests: XCTestCase {

    // MARK: Internal

    func testSpaceshipCanLaunch() {
      launchSpaceship()
      XCTAssertTrue(spaceship.hasLaunched)
    }

    // MARK: Private

    private let spaceship = Spaceship()

    private func launchSpaceship() {
      spaceship.launch()
    }

  }
  ```

  </details>

* <a id='avoid-force-unwrap-in-tests'></a>(<a href='#avoid-force-unwrap-in-tests'>link</a>) **Avoid force-unwrapping in unit tests**. Force-unwrapping (`!`) will crash your test suite. Use safe alternatives like `try XCTUnwrap` or `try #require`, which will throw an error instead, or standard optional unwrapping (`?`). [![SwiftFormat: noForceUnwrapInTests](https://img.shields.io/badge/SwiftFormat-noForceUnwrapInTests-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#noForceUnwrapInTests)

  <details>

  ```swift
  import XCTest

  final class SpaceshipTests: XCTestCase {
    // WRONG
    func testCanLaunchSpaceship() {
      let spaceship = (dependencies!.shipyardService as! DefaultShipyardService).build()
      spaceship.engine!.prepare()
      spaceship.launch(to: nearestPlanet()!)
      
      XCTAssertTrue(spaceship.hasLaunched)
      XCTAssertEqual(spaceship.destination! as! Planet, nearestPlanet())
    }

    // RIGHT
    func testCanLaunchSpaceship() throws {
      let spaceship = try XCTUnwrap((dependencies?.shipyardService as? DefaultShipyardService)?.build())
      spaceship.engine?.prepare()
      spaceship.launch(to: try XCTUnwrap(nearestPlanet()))
      
      XCTAssertTrue(spaceship.hasLaunched)
      XCTAssertEqual(spaceship.destination as? Planet, nearestPlanet())
    }
  }
  ```

  ```swift
  import Testing

  struct SpaceshipTests {
    // WRONG
    @Test
    func canLaunchSpaceship() {
      let spaceship = (dependencies!.shipyardService as! DefaultShipyardService).build()
      spaceship.engine!.prepare()
      spaceship.launch(to: nearestPlanet()!)
      
      #expect(spaceship.hasLaunched)
      #expect((spaceship.destination! as! Planet) == nearestPlanet())
    }

    // RIGHT
    @Test
    func canLaunchSpaceship() throws {
      let spaceship = try #require((dependencies?.shipyardService as? DefaultShipyardService)?.build())
      spaceship.engine?.prepare()
      spaceship.launch(to: try #require(nearestPlanet()))
      
      #expect(spaceship.hasLaunched)
      #expect((spaceship.destination as? Planet) == nearestPlanet())
    }
  }
  ```
  </details>

* <a id='remove-redundant-effects-in-tests'></a>(<a href='#remove-redundant-effects-in-tests'>link</a>) **Remove redundant `throws` and `async` effects from test cases**. If a test case doesn't throw any errors, or doesn't `await` any `async` method calls, then `throws` and `async` are redundant. [![SwiftFormat: redundantThrows](https://img.shields.io/badge/SwiftFormat-redundantThrows-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#redundantThrows) [![SwiftFormat: redundantAsync](https://img.shields.io/badge/SwiftFormat-redundantAsync-7B0051.svg)](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md#redundantAsync)

  <details>

  ```swift
  import XCTest

  final class PlanetTests: XCTestCase {
    // WRONG
    func test_habitability() async throws {
      XCTAssertTrue(earth.isHabitable)
      XCTAssertFalse(mars.isHabitable)
    }

    // RIGHT
    func test_habitability() {
      XCTAssertTrue(earth.isHabitable)
      XCTAssertFalse(mars.isHabitable)
    }
  }
  ```

  ```swift
  import Testing

  struct PlanetTests {
    // WRONG
    @Test
    func habitability() async throws {
      #expect(earth.isHabitable)
      #expect(!mars.isHabitable)
    }

    // RIGHT
    @Test
    func habitability() {
      #expect(earth.isHabitable)
      #expect(!mars.isHabitable)
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
