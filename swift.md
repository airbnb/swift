# Airbnb iOS Style Guide

*Swift*

# Swift Style Guide

* Capitalize constants, and prefer putting them in the top level of a class if they are private. If they are public, put the constant as a static property, so we get nice namespaces.  
```swift
private let PrivateValue = "secret"
  
class MyClass {
  static let PublicValue = "something"

  func doSomething() {
    print(PrivateValue)
	print(MyClass.PublicValue)
  }
}
```

* Don't include types when they can be easily inferred
** Declaring identifiers
```swift
// WRONG
let something: MyClass = MyClass()

// RIGHT:
let something = MyClass()

```
*** Do include the type for `CGFloat`s because they don't auto-bridge with `Double` or `Int`
```swift
// RIGHT
let someMargin: CGFloat = 5
// WRONG
let someMargin = CGFloat(5)
```
** Enum cases
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

* Don't use self unless it's necessary for disambiguation or required by the language. 
```swift
class MyClass {
  var aProp: Int

  init(aProp: Int) {
	// okay to use self here
    self.aProp = aProp
  }
    
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

* Try to initialize properties in the init() method whenever possible, rather than using implicitly unwrapped optionals.  (Notable exception is UIViewController.)
```swift
// WRONG
class MyClass: NSObject {
  var someValue: Int!
  init() {
    super.init()
    someValue = 5
  }
}

// RIGHT
class MyClass: NSObject {
  var someValue: Int
  init() {
    someValue = 0
    super.init()
  }
}
```

* Use functions instead of computed properties if they get to be complicated. Also avoid didSet and willSet for the same reason. 
```swift
// WRONG
// this is less readable
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
// easier to read and clearer that there are side effects of setting or nontrivial computation going on
class MyClass {
  func someValue() -> Int {
  }
  
  func setSomeValue(newValue: Int) {
  }
}
```
* Separate long function declarations on each argument and put the open curly on the next line so the body is indented correctly. 
```swift
class MyClass {
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
* Long function invocations should also break on each argument, and also put the closing parenthesis on the following line. 
```swift
foo.doSomething(4, 
  anotherArg: 5,
  yetAnotherArg: 4,
  andOneMoreArgForGoodMeasure: "oaiwjeifajwe"
)
```
    
* Avoid large callback blocks - instead organize them into methods.  This makes weak-self in blocks much simpler.
```swift
    // WRONG
    class MyClass {
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
      func doRequest(completion: () -> Void) {
        API.request() { [weak self] response in 
          self?.processResponse(response)
          completion()
        }
      }
      
      func processResponse(response) {
        // do actual processing here
      }
    }
```
      
* Only add guard to top of functions. Goal of guard is to reduce branch complexity and in some ways adding guard statements in the middle of a chunk of code increases complexity

* How do we deal with multiple let clauses in an if clause?
```swift
    // This feels weird, but is how autoindent works right now in XCode
    if
      let val1 = val1,
      let val2 = val2
      where !val2.isEmpty {
      print(val2)
    }
    
    // Putting the first let on the same line as the if makes the body indent an extra level
    // This also looks kind of gross
    if let val1 = val1,
      let val2 = val2
      where !val2.isEmpty {
        print(val2)
    }
```
* Proposal: Keep if-let statements simple and to one line, otherwise use multiple guard statements

* Don’t include return type Void in blocks even though that’s what autocomplete does
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

* Prefer immutable values whenever possible. use `map` and `flatMap` instead of appending to a new collection.  Use filter instead of removing elements from a mutable collection. Mutable variables increase complexity, so try to keep them in as narrow a scope as possible. 
```swift
// WRONG
func computeResults(input: [String]) -> [SomeType] {
  var results = [SomeType]()
  for element in input {
    let result = transform(element)
    results.append(result)
  }
}

// RIGHT
func computeResults(input: [String]) -> [SomeType] {
  let results = input.map(transform)
  return anotherExample
}

func computeResults(input: [String]) -> [SomeType] {
  let anotherExample = input.map { $0.something }
}


// Use flatMap to filter optionals
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
  let results = input.flatMap(transformThatReturnsAnOptional)
  return results
}

// WRONG
func updateDisplayedData() {
  var data = dataSource.getData()

  // Apply first transformation to data
  for key in data.keys {
    data[key] = massageValue(data[key])
  }

  // Apply second transformation to data
  for key in data.keys {
    data[key] = beatUpValue(data[key])
  }

  // Display transformed data
  display(someHash)
}

// RIGHT 
func updateDisplayedData() {
  let data = dataSource.getData()
  let massagedData = massageData(data)
  let beatUpData = beatUpData(massagedData)
  display(beatUpData)
}
```
* Avoid using optionals unless there’s a good semantic meaning.

* Name members of tuples for extra clarity. If you've got more than 3 fields, you should use a struct. 
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

* Use constructors instead of *Make() functions for CGRect, CGPoint, NSRange and others
```swift
// WRONG
let rect = CGRectMake(10, 10, 10, 10)

// RIGHT
let rect = CGRect(x: 0, y: 0, width: 10, height: 10)
```

* The colon always goes immediately after the identifier, followed by a space
```swift
// WRONG
var something : Int = 0

// RIGHT
var something: Int = 0

// WRONG
class MyClass : SuperClass { 
}

// RIGHT
class MyClass: SuperClass {
	
}

// WRONG
var dict = [KeyType:ValueType]()
var dict = [KeyType : ValueType]()

// RIGHT
var dict = [KeyType: ValueType]()
```


