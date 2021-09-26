## Usage

### How to use SwiftConnect?

To start using SwiftConnect you must be aware of the following key concepts.

#### Connect

Is the basic class that contains three functions (request / upload / cancelAllRequests) it can be instantiated directly using Connect() or you can customize its parameters, Its constructor contains two parameters (ConnectMiddleware / ErrorHandler) which will be discussed shortly. Or you can just use Connect.default to get the default implementation of SwiftConnect.

#### ConnectMiddleware

ConnectMiddleware is a class that conforms to ConnectMiddlewareProtocol which has the following requirements
```swift
public protocol ConnectMiddlewareProtocol: RequestAdapter, RequestRetrier {
    var session: Session { get }
}
```
Any class that implements ConnectMiddlewareProtocol must have the session variable and adapt the two protocols RequestAdapter / RequestRetier from Alamofire.

The core of this class is mainly used for adapting requests / handling unauthorized states (currently SwiftConnect does not support that but it will support it in the near future) so if you want to roll your own implementation you are free to do so.

#### ErrorHandler

ErrorHandler is a class that conforms to ErrorHandlerProtocol which has the following requirements
```swift
public protocol ErrorHandlerProtocol {
    func handle(response: [String: Any]) -> Error?
}
```

Error handling can be really tricky, it has no unified standards across all the backend developers, some people return an array, some people return a dictionary, some people use "message" other use "msg" and so on, the possibilities are unlimited so when I initially decided to approach this I thought to myself "well, let's leave that to the developer" which leaves us to an important question, How does SwiftConnect handle errors ?

First and foremost SwiftConnect assumes a request is successful if it's status code is within the acceptable range (200..<300) but in case it fails and the error code is something that's unacceptable that's where the ErrorHandler kicks in and calls "handle(response: [String: Any])" and its your own responsibility to decide the error that will be thrown. You may even return nil in case you assume that the request is successful even when it failed (for some reason ?). 

If you don't provide ErrorHandler and just use the default implementation it's going to lookup the following keys (msg, messge, error, err) before giving up and throwing a generic error.

#### Connector

Connector is the core protocol that builds a network request.

Creating a new connector is very simple you just have to conform to Connector Protocol which has the following requirements
```swift
public protocol Connector: Alamofire.URLRequestConvertible {
    var baseURL: URL { get }
    var endpoint: String { get }
    var method: HTTPMethod { get }
    var headers: [HTTPHeader] { get }
    var parameters: ParametersRepresentable? { get }
}
```

Let's take a look at an example Connector
```swift
enum TodoConnector: Connector {
    
    case get(id: Int)
    
    var baseURL: URL {
        return URL(string: "https://jsonplaceholder.typicode.com")!
    }
    
    var endpoint: String {
        switch self {
        case .get:
            return "/todos/{id}"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .get:
            return .get
        }
    }
    
    var headers: [HTTPHeader] {
        return []
    }
    
    var parameters: ParametersRepresentable? {
        switch self {
        case .get(let id):
            return Parameter.path(key: "id", value: "\(id)")
        }
    }
}
```

So all of these requirements are pretty self explantory except for one specific requirement (parameters).

SwiftConnect introduces two new types of parameters (Parameter / CompositeParameters)

### What is Parameter?

Parameter is a simple enum that has three cases (query, path, jsonObject)

```swift
public enum Parameter: ParametersRepresentable {
    case query(key: String, value: String)
    case path(key: String, value: String)
    case jsonObject(value: Encodable)
}
```

Assuming your request requires only one parameter you may return one of these for the parameters property.

The query type will append the parameter to url query components whereas the path parameter will look for the specified key in the URL and replace it with the specified value, I.E if you pass Parameter.path(key: "id", value: "123") for the parameters (as in the example above) SwiftConnect will look for {id} in the Endpoint and replace it with 123

**You must make sure you match the path parameters key with their respective values in the URL**

And finally passing Parameter.jsonObject(someJSONObject) will encode the given object and send it in the body of the request.

### What is CompositeParameters?

CompositeParameters is a very basic, yet powerful data structure that allows you to compose different parameters for your request. Let's take a look about how can we make use of this to construct a request with different parameter types without any string manipulation (in case of path parameters) in order to create a request.

Let's assume the following URL 

https://myserver.com/users/1/todos/5?action=done

And also let's assume you need to pass a json object as well in the parameters. Can you imagine the nightmares ? constructing this URL will be very complex but with CompositeParameters it's very very simple. Let's take a look at example Connector that does this.

```swift
enum TodoAction: String {
    case update
}

enum AdvancedTodoConnector: Connector {
    
    case update(userId: Int, todoId: Int, action: TodoAction, object: Encodable)
    
    var baseURL: URL {
        return URL(string: "https://myserver.com")!
    }
    
    var endpoint: String {
        switch self {
        case .update:
            return "/users/{userId}/todos/{todoId}"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .update:
            return .put
        }
    }
    
    var headers: [HTTPHeader] {
        return []
    }
    
    var parameters: ParametersRepresentable? {
        switch self {
        case .update(let userId, let todoId, let action, let object):
            return CompositeParameters(
                .path(key: "userId", value: "\(userId)"),
                .path(key: "todoId", value: "\(todoId)"),
                .query(key: "action", value: action.rawValue),
                .jsonObject(value: object)
            )
        }
    }
}
```

Calling this Connector will result into this call

```bash
=======================================
$ curl -v \
    -X PUT \
    -H "User-Agent: SwiftConnect Example/1.0 (com.swiftconnect.example; build:1; iOS 13.3.0) Alamofire/5.1.0" \
    -H "Accept-Language: en-US;q=1.0, ar-US;q=0.9, en;q=0.8" \
    -H "Accept-Encoding: br;q=1.0, gzip;q=0.9, deflate;q=0.8" \
    -H "Content-Type: application/json" \
    -d "{\"userId\":2,\"id\":1,\"title\":\"Test Todo\",\"completed\":false}" \
    "https://myserver.com/users/1/todos/2?action=update"
=======================================
```

#### AuthorizedConnector

AuthorizedConnector is a very simple protocol which has the following requirements
```swift
public protocol AuthorizedConnector {
    var authorizationToken: AuthorizationToken? { get }
}
```
The role of AuthorizedConnector is basically allow any connector to send the specified authorization token if the route that you are requesting is authenticated (say goodbye to hardcoding those stuff in the headers !)
You may return an AuthorizationToken if your route requires authentication or nil if the route is unauthenticated.

AuthorizationToken is another simple enum that contains only three cases
```swift
public enum AuthorizationToken {
    case bearer(token: String), basic(username: String, password: String), custom(token: String)
}
```
So in nutshell, SwiftConnect supports Bearer, Basic, Custom authentication.

#### File (for uploading tasks)

File is a very simple struct that does what its named, represents a file.
```swift
public struct File {
    let name: String
    let key: String
    let mimeType: MimeType
    let data: Data
}
```
File also includes MimeType which is a struct that contains various mime types and is extendible
```swift
public struct MimeType: RawRepresentable, Equatable, Hashable {
    
    static let jpg = MimeType(rawValue: "image/jpeg")
    static let png = MimeType(rawValue: "image/png")
    static let mp4 = MimeType(rawValue: "video/mp4")
    static let pdf = MimeType(rawValue: "application/pdf")

    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}
```

You can define a new MimeType easily by doing the following
```swift
extension MimeType {
    static let myAwesomeType = MimeType(rawValue: "awesome/type")
}
```

#### Using Connect
Connect allows you to either do a normal request or do an upload task and it's defined with the following method signatures
```swift
public func request(_ request: Connector, debugResponse: Bool = false) -> Future<Data>
public func upload(files: [File]?, to request: Connector, debugResponse: Bool = false) -> Future<Data>
```

After doing all the chaining for Future you finally call .observe which is an async closure that has one variable Result<Type, Error> whereas  the Type is the final data type returned from your Futures Chain.

##### Example for the Connector provided above
```swift
Connect.default.request(TodoConnector.get(id: 123), debugResponse: true).decoded(toType: Todo.self).observe { result in
    switch result {
    case .success(let todo):
        print(todo)
    case .failure(let error):
        print(error)
    }
}
```
The observe closure here will be of type Result<Todo, Error>
