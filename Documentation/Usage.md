## Usage

### How to use SwiftConnect?

To start using SwiftConnect you must be aware of the following key concepts.

#### Connect

Is the basic class that contains three functions (request / upload / cancelAllRequests) it can be instantiated directly using Connect() or you can customize its parameters, Its constructor contains two parameters (ConnectMiddleware / ErrorHandler) which will be discussed shortly. Or you can just use Connect.default to get the default implementation of SwiftConnect.

---

#### ConnectMiddleware

ConnectMiddleware is a class that conforms to ConnectMiddlewareProtocol which has the following requirements
```swift
public protocol ConnectMiddlewareProtocol: RequestAdapter, RequestRetrier {
    var session: Session { get }
}
```
Any class that implements ConnectMiddlewareProtocol must have the session variable and adapt the two protocols RequestAdapter / RequestRetier from Alamofire.

The core of this class is mainly used for adapting requests / handling unauthorized states (currently SwiftConnect does not support that but it will support it in the near future) so if you want to roll your own implementation you are free to do so.

---

#### ErrorHandler

ErrorHandler is a class that conforms to ErrorHandlerProtocol which has the following requirements
```swift
public protocol ErrorHandlerProtocol {
    func handle(response: [String: Any]) throws
}
```

Error handling can be really tricky, it has no unified standards across all the backend developers, some people return an array, some people return a dictionary, some people use "message" other use "msg" and so on, the possibilities are unlimited so when I initially decided to approach this I thought to myself "well, let's leave that to the developer" which leaves us to an important question, How does SwiftConnect handle errors ?

First and foremost SwiftConnect assumes a request is successful if it's status code is within the acceptable range (200..<300) but in case it fails and the error code is something that's unacceptable that's where the ErrorHandler kicks in and calls "handle(response: [String: Any])" and its your own responsibility to decide the error that will be thrown. You may even return nil in case you assume that the request is successful even when it failed (for some reason ?). 

If you don't provide ErrorHandler and just use the default implementation it's going to lookup the following keys (msg, messge, error, err) before giving up and throwing a generic error.

---

##### Requestable

`Requestable` is the core protocol that builds a network request, it backs two different upper protocols (`Request`, `MultipartRequest`) with the former being used for the requests which are normal and the latter for the requests that has files

Creating a new request is very simple you just have to conform to either `Request` / `MultipartRequest` protocol both requirements are inherited from the `Requestable` which is defined as below 

```swift
public protocol Requestable: Alamofire.URLRequestConvertible {
    var baseURL: URL { get }
    var endpoint: String { get }
    var method: HTTPMethod { get }
}
```

If you decide to implement `MultipartRequest` protocol you'll have an extra variable `files` which are used to pass in the files for the multipart request

Let's take a look at an example Request
```swift
struct GetTodoRequest: Request {
    
    let baseURL = URL(string: "https://jsonplaceholder.typicode.com")!
    let endpoint = "/todos/{id}"
    let method: HTTPMethod = .get
    
    @Path("id") private(set) var todoId: Int
    
    init(todoId: Int) {
        self.todoId = todoId
    }
}
```

So all of these requirements are pretty self explantory except for one specific mystery that showed up `@Path` 
For all of our Android friends you probably know what's the deal here but for our iOS friends who don't know what is `Retrofit` or how it works, I'll explain further on how all of this magic happens and what other types are supported

SwiftConnect introduces five types of `propertyWrappers` which can be used to add parameters / headers to your request.
Under the hood, SwiftConnect uses `reflection` to resolve these parameters at run time, I know reflection is scary and everything but throughout my benchmarking the difference between explicitly defining parameters and resolving them in runtime via reflection was so negligible that I didn't even bother to build one gigantic file that conforms to `URLRequestConveritble` and grows vertically as the project grows 

---

### Available propertyWrappers

* `@Query`
* `@Path`
* `@RawData`
* `@Object`
* `@Header`

#### What is `@Query`?

Query propertyWrapper is used to append query parameters to the request.
Its constructor is defined as following

```swift
init(_ key: String, encoding: URLEncoding = .default)
```

It accepts two parameters, the first being the key that will be appended to the request and the encoding which is defaulted to `URLEncoding.default`, if you wish to customize how it's encoded you can pass another instance of `URLEncoding` I.E (brackets vs no brackets / boolean encoding literal vs non-literal)

Any variable preceded by `@Query` must conform to `CustomStringConveritbleProtocol`

---

#### What is `@Path`?

Path propertyWrapper is used to append path parameters to the request.
Its constructor is defined as following

```swift
init(_ key: String, encoding: PathEncoding = .default)
```

It accepts two parameters, the first being the key that will be appended to the request and the encoding which is defaulted to `PathEncoding.default`, if you wish to customize how it's encoded you can pass another instance of `PathEncoding`

`PathEncoding` itself is a new addition from SwiftConnect which adds the ability to define how do you want your path parameters to be parsed, the default pattern that's detected is `{key}` so looking at the example request above it defines its endpoint as `"/todos/{id}"` at run time, the pattern that will be matched against is anything surrounded by curly braces and will be replaced by the respective value, given that the passed `key` to `@Path` matches the value in the string.

If you want to customize how the keys are replaced simply create a new instance from `PathEncoding` like the following

```swift
PathEncoding(pattern: "##key##")
```

Then at your request we'll edit the endpoint to be from `"/todos/{id}"` to `"/todos/##id##"`, so it's totally up to you how to define it, just make sure that the path paremeters key is matched with with their respctive values in the endpoint.

---

#### What is `@RawData`?

RawData propertyWrapper is used to send raw data without anything else, which means if you have RawData in your request it'll simple override everything internally it sets the httpBody value of the request

It has no defined constructor, you just pass in the data you want and it'll inject it into the URLRequest

---

#### What is `@Object`?

Object propertyWrapper is the most complex one of all of them because it's used to send encodable objects in the request.
Its constructor is defined as following

```swift
init(encoder: JSONEncoder = JSONEncoder(), encoding: ParameterEncoding)
```

It has one default argument which is the encoder, if you want to customize how the object is encoded you can provide your own customized JSONEncoder, by default SwiftConnect includes and extension for both `JSONDecoder`, `JSONEncoder` which are `.snakeCaseDecoder` and `.snakeCaseEncoder` respectively, since this is very common case.

You can even create a big object and pass it all to the query parameters if needed by setting the encoding to be URLEncoding.default.

---

#### What is `@Header`?

Header propertyWrapper is used to add headers to your request (non-authorization headers, we'll get to the authorizaton shortly)

Its constructor is defined as following

```swift
init(_ key: String)
```

You just need to pass the key that'll be appended to headers and set the value, then the header will be injected at the time of building the request

---

### Creating complex request

Creating complex requests can be very complex when it comes to real life projects

SwiftConnect introduces combination of propertyWrappers above to compose different parameters for your request. Let's take a look about how can we make use of this to construct a request with different parameter types without any string manipulation (in case of path parameters) in order to create a request.

Let's assume the following URL 

https://myserver.com/users/1/todos/5?action=done

And also let's assume you need to pass a json object in the parameters (because why not ?)
Can you imagine the nightmares ? constructing this Request will be very complex but with propertyWrappers it's very very simple. Let's take a look at example Request that does this.

```swift
struct Todo: Encodable {
    let title: String
    let isCompleted: Bool
}

enum TodoAction: String {
    case update
}

extension TodoAction: CustomStringConvertible {
    
    var description: String {
        return rawValue
    }
    
}

struct UpdateTodoRequest: Request {
    let baseURL = URL(string: "https://myserver.com")!
    let endpoint = "/users/{userId}/todos/{todoId}"
    let method: HTTPMethod = .put
    
    @Path("userId") private(set) var userId: Int
    @Path("todoId") private(set) var todoId: Int
    //Note here we defined an explicit encoding because by default if method is not get it'll replace the body
    @Query("action", encoding: URLEncoding(destination: .queryString)) private(set) var action: TodoAction
    @Object(encoding: JSONEncoding.default) private(set) var todo: Todo
    
    init(userId: Int, todoId: Int, action: TodoAction, todo: Todo) {
        self.userId = userId
        self.todoId = todoId
        self.action = action
        self.todo = todo
    }
}
```

Calling this Request will result into this call

```bash
=======================================
$ curl -v \
    -X PUT \
    -H "User-Agent: SwiftConnect Example/1.0 (com.swiftconnect.example; build:1; iOS 13.3.0) Alamofire/5.1.0" \
    -H "Accept-Language: en-US;q=1.0, ar-US;q=0.9, en;q=0.8" \
    -H "Accept-Encoding: br;q=1.0, gzip;q=0.9, deflate;q=0.8" \
    -H "Content-Type: application/json" \
    -d "{\"isCompleted\":true,\"title\":\"test\"}" \
    "https://myserver.com/users/123/todos/1234?action=update"
=======================================
```

Simple, yet elegant !

---

#### AuthorizedRequest

AuthorizedRequest is a very simple protocol which has the following requirements

```swift
public protocol AuthorizedRequest {
    var authorizationToken: AuthorizationToken? { get }
}
```
The role of AuthorizedRequest is basically allow any request to send the specified authorization token if the route that you are requesting is authenticated (say goodbye to hardcoding those stuff in the headers !)
You may return an AuthorizationToken if your request requires authentication or nil if the route is unauthenticated.

AuthorizationToken is another simple enum that contains only three cases
```swift
public enum AuthorizationToken {
    case bearer(token: String), basic(username: String, password: String), custom(key: String, token: String)
}
```
So in nutshell, SwiftConnect supports Bearer, Basic, Custom authentication.

---

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

---

#### Using Connect
Connect allows you to either do a normal request or do an upload task and it's defined with the following method signatures
```swift
public func request(request: Request, debugResponse: Bool = false) async throws -> Response
public func request(multipartRequest: MultipartRequest, debugResponse: Bool = false) async throws -> Response
```

##### Example for the Request provided above
```swift
do {
    let todo = try await Connect.default.request(request: GetTodoRequest(id: 123), debugResponse: true).decoded(toType: Todo.self)
    print(todo)
} catch {
    debugPrint(error)
}
```

---

### Module

A module is very simple by definition it describes entities on your application, for example if you are building a social media application you'd have the following modules (Post, Story, Comment).
Each module encapsulates bunch of requests for accessibility so that you don't need to remember request names by heart.

Module protocol is simply defined as 

```swift
public protocol Module {
    var request: Requestable { get }
}
```

Any conforming object should implement the `request` property which will be used to build the network request

#### Building Modules

Let's take the example above and build a Post module that will encapsulate all requests related to `Post` module in our social media apps.
Implementaion will look seomthing like this

```swift
enum PostEndpoints {
    static let post = "/posts/{postId}"
    static let posts = "/posts"
}
```

```swift
struct GetPost: Request {
    
    let baseURL: URL = URL(string: "https://www.myserver.com")!
    let endpoint: String = PostEndpoints.post
    let method: HTTPMethod = .get
    
    @Path("postId") private(set) var postId: String
    
    init(postId: String) {
        self.postId = postId
    }
}
```

```swift
struct CreatePost: MultipartRequest {
    
    let baseURL: URL = URL(string: "https://www.myserver.com")!
    let endpoint: String = PostEndpoints.posts
    let method: HTTPMethod = .post
    
    let files: [File]
    @Object(encoding: JSONEncoding.default) private(set) var post: Post
    
    init(files: [File], post: Post) {
        self.files = files
        self.post = post
    }
    
}
```


```swift
enum PostModule: Module {
    
    case get(postId: String)
    case create(files: [File], post: Post)
    
    var request: Requestable {
        switch self {
        case .get(let postId):
            return GetPost(postId: postId)
            
        case .create(let files, let parameters):
            return CreatePost(files: files, post: parameters)
        }
    }
    
}
```
The above implementation will allow us simply to group all the requests under a related module for an easier accessibility.

To use the above module you can simply do the following

```swift
let request = PostModule.get(postId: "123").request

do {
    try await Connect.default.request(request: request, debugResponse: true)
} catch {
    debugPrint(error)
}
```

Building modules is totally optional and you are free to either do it or not, it's simply a better way to express your requests under a certain "namespace"

#### Cancelling Requests

Cancelling requests is pretty much necessary nowadays and most of the abstraction layers that are build don't account for request cancellation, So what if we are doing a search and we'd like to cancel previous requests if two requests run simultaneously.


Instead of using the `request` method, we'll instead use another two methods the first one being

`public func makeDataTask(request: Requestable) -> DataTask<Data>`

and the second one being

`public func execute(task: DataTask<Data>, debugResponse: Bool = false) async throws -> Response`

- We'll create a Task
- Store it somewhere so that we can cancel it later
- Execute the task using the method above

```swift
class ViewModel {
    //...Your Implementation
    private var task: DataTask<Data>?
    
    func search(term: String) async throws {
        task?.cancel()
        task = nil
        let request = PostModule.search(term: term).request
        task = Connect.default.makeDataTask(request: request)
        let results = try await Connect.default.execute(task: task!).decoded(toType: [Post.self])
        print(results)
    }
}

```

Similarly there's a function to create a DataTask for multipart requests so that you can cancel your upload requests if user does a certain action for example

`public func makeUploadTask(request: Requestable) -> DataTask<Data>`
