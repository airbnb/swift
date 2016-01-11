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
* Separate long function names on each argument and put the open curly on the next line so the body is indented correctly. 
```swift
class MyClass {
  // WRONG
  func doSomething(arg: Int, anotherArg: Int, yetAnotherArg: Int, andOneMoreArgForGoodMeasure: String) {
      // This is just too long and will probably auto-wrap in a weird way
  }
  
  // WRONG
  func doSomething(arg: Int,
    anotherArg: Int,
    yetAnotherArg: Int,
    andOneMoreArgForGoodMeasure: String) {
      // XCode will indent the body an extra level in
  }
  
  func doSomething(
    arg: Int,
    anotherArg: Int,
    yetAnotherArg: Int,
    andOneMoreArgForGoodMeasure: String) 
  {
    // Will cause correct level of indentation
  }
}  
  
// Invokation:
foo.doSomething(4, 
  anotherArg: 5,
  yetAnotherArg: 4,
  andOneMoreArgForGoodMeasure: "oaiwjeifajwe")

```
    
* Avoid large callback blocks - instead organize them into methods.  This makes weak-self in blocks much simpler.
```swift
    // WRONG
    class MyClass {
      func doRequest(completion: () -> Void) {
        API.request() { response in
          // lots of processing and whatever
          completion()
        }
      }
    }
    
    // RIGHT
    class MyClass {
      func doRequest(completion: () -> Void) {
        API.request() { response in 
          self.processResponse(response)
          completion()
        }
      }
      
      func processResponse(response) {
        // do actual processing here
      }
    }
```
      
* Guard
    * Only add to top of functions. Goal of guard is to reduce branch complexity and in some ways adding guard statements in the middle of a chunk of code increases complexity

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

* prefer immutable values whenever possible. use map and flatmap instead of appending to a new array.  mutable variables increase complexity, so try to keep them in as small a scope as possible if you have to use them. 
```swift
	// WRONG
    var results = []
    for element in input {
      let result = transform(element)
      results.append(result)
    }
    
    // RIGHT
    let results = input.map(transform)
    
    // WRONG
    func doSomething() {
      var someHash = getHashFromSomewhere()
      someHash["someNewKey"] = someComputation()
      doSomethingWithHash(someHash)
    }
    
    // RIGHT 
    func doSomething() {
      let someHash = getHashFromSomewhere()
      let modifiedHash = modifyHash(someHash)
      doSomethingWithHash(modifiedHash)
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

* where do we want the colon to go?
** The colon always goes immediately after the identifier, followed by a sapce
`var something: Int`
** For type declarations, it's not clear what is better
```swift
// OKAY?
class MyClass : SuperClass { 
}

// OKAY?
class MyClass: SuperClass {
	
}
```
** for dictionaries, have space on both sides of the colon, (except for an empty dictionary literal `[:]`)
`var dict = [KeyType : ValueType]()`
