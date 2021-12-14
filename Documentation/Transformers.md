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
public extension Future where Value == Data {
    func dictionary() -> Future<[String: AnyObject]>
}

public extension Future where Value == Data {
    func get<NextValue>(key: String, ofType type: NextValue.Type) -> Future<NextValue?>
}
```

With dictionary transformer you may want to create a dictionary from the response and use it directly without mapping it to any model, or maybe even get a specific key from the dictionary it also supports keypaths (the separator is .) so you can do something like "get.some.key.thats.nested.deeply".

---

#### Void Transformer
```swift
public extension Future where Value == Data {
    func asVoid() -> Future<Void>
}
```

With void transformer you may want to ignore the content of the response altogether and just care about its error in case of a failure therefore the void transformer is created specifically for that.

---

#### Reactive Transformers

Do you like to use any reactive programming library ? (RxSwift / Bond / ReactiveSwift)
SwiftConnect also supports transforming for its Future / Promise type to any kind of  `Observable`  you'd need

Here are two examples for such transformation

```swift
import Foundation
import SwiftConnect
import Bond
import ReactiveKit

public extension Future {
    func asSignal() -> Signal<Value, Error> {
        return Signal { observer in
            self.observe { result in
                switch result {
                case .success(let value):
                    observer.on(.next(value))
                    observer.on(.completed)
                    
                case .failure(let error):
                    observer.on(.failed(error))
                }
            }
            return SimpleDisposable(isDisposed: false)
        }
    }
}
```

```swift
import Foundation
import SwiftConnect
import RxSwift

public extension Future {
    func asObservable() -> Observable<Value> {
        return Observable.create { observer in

            self.observe { result in
                switch result {
                case .success(let value):
                    observer.onNext(value)
                    observer.onCompleted()
                    
                case .failure(let error):
                    observer.onError(error)
                }
            }

            return Disposables.create {
                self.cancel()
            }
        }
    }
}

public extension Future {
    func asSingle() -> Single<Value> {
        asObservable()
            .asSingle()
    }
}

public extension Future {
    func asCompletable() -> Completable {
        asSingle()
            .asCompletable()
    }
}
```

Super easy !

---

#### Creating your own transformer

The core power of SwiftConnect is the ability to create your own transformers which makes it very extendible.
Let's take a look on how can we create a String Transformer that transforms Data to String.

```swift
extension Future where Value == Data {
    func asString() -> Future<String> {
        return transformed {
            return String(data: $0, encoding: .utf8) ?? ""
        }
    }
}
```

Very simple isn't it ? create an extension of Future where Value == Data then do your transformation on a function of your name choice.

Maybe we want to transform this String into a URL directly ?
```swift
extension Future where Value == String {
    func asURL() -> Future<URL?> {
        return transformed {
            return URL(string: $0)
        }
    }
}
```

And you can keep chaining this as long as you want as long as you are matching the data types.

Then you can simply chain the call by doing

```swift
Connect.default.request(request: ExampleModule.example.request).asString().asURL().observe { result in
    //result here will be of type Result<URL?, Error>
}
```

This plays very well with repository design pattern, maybe you can create a transformer that saves the data to your local db directly ? the possibilities are unlimited yet the code is very simple.
