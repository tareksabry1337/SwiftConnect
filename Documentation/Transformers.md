## Transformers

### Let's take a look on some of the built in Transformers that come out of the box with SwiftConnect.

#### Codable Transformer
```swift
public extension Response {
    func decoded<Model: Decodable>(toType type: Model.Type, keyPath: String = "") throws -> Model
}
```

A very simple transformer that creates a decodable model from given data and it supports keypath as well.

#####  What is keypath support when it comes to JSONDecoding ?

Say you have a `Item` model
```swift
struct Item: Codable {
    let id: Int
    let name: String
}
```

And we have a following JSON:
```JSON
{
   "item" : {
      "id": 123,
      "name": "Test"
   }
}
```

In normal cases you'll create a "container" for this struct to represent this JSON so maybe something like 
```swift
struct ItemContainer: Codable {
    let item: Item
}
```

Then you'll decode it using
```swift
let itemContainer = try decoder.decode(ItemContainer.self, from: jsonData)
```

But with the powerful keypaths you can do it like that
```swift
let item = try decoder.decode(Item.self, from: jsonData, keyPath: "foo")
```

This will eliminate all the boilerplate in your models and allows for a clear and concrete data structure

---

#### Dictionary Transformer
```swift
public extension Response {
    func dictionary() -> [String: AnyObject]
}

public extension Response {
    func get<Value>(key: String, ofType type: Value.Type) -> Value?
}
```

With dictionary transformer you may want to create a dictionary from the response and use it directly without mapping it to any model, or maybe even get a specific key from the dictionary it also supports keypaths (the separator is .) so you can do something like "get.some.key.thats.nested.deeply".

---

#### Void Transformer
```swift
public extension Response {
    func asVoid()
}
```

With void transformer you may want to ignore the content of the response altogether and just care about its error in case of a failure therefore the void transformer is created specifically for that.

---

#### Creating your own transformer

The core power of SwiftConnect is the ability to create your own transformers which makes it very extendible.
Let's take a look on how can we create a String Transformer that transforms Data to String.

```swift
extension Response {
    func asString() -> String {
        return String(data: data, encoding: .utf8) ?? ""
    }
}
```
Very simple isn't it ? You are literally just extending a struct and implementing functions of your own choice !

Maybe we want to transform this String into a URL directly ?

```swift
extension Response {
    func asURL() -> URL? {
        let string = self.asString()
        return URL(string: string)
    }
}
```

And you can keep chaining this as long as you want as long as you are matching the data types.

Then you can simply chain the call by doing

```swift
do {
    let url = try await Connect.default.request(request: ExampleModule.example.request).asURL()
    print(url)
} catch {
    debugPrint(error)
}
```

This plays very well with repository design pattern, maybe you can create a transformer that saves the data to your local db directly ? the possibilities are unlimited yet the code is very simple.
