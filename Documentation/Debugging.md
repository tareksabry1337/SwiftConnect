## Debugging in SwiftConnect

### Debugging Network Requests

Debugging network requests can be a real bane and nightmare, the famous phrase that we always hear "It works on Postman" its your own fault but Connect makes debugging network requests really easy.
First of all any request that goes out of your device will be logged to the console automatically and can be seen in this format

```bash
=======================================
$ curl -v \
    -X GET \
    -H "Accept-Encoding: br;q=1.0, gzip;q=0.9, deflate;q=0.8" \
    -H "User-Agent: Connect Example/1.0 (com.connect.example; build:1; iOS 13.3.0) Alamofire/5.1.0" \
    -H "Accept-Language: en-US;q=1.0, ar-US;q=0.9, en;q=0.8" \
    "https://jsonplaceholder.typicode.com/todos/123"
=======================================
```
This makes it really easy to find out what's wrong with your request at glance, no more stopping at break points to find out what's wrong with the request or if there's an incorrect parameter name being sent.

Further more if you want to debug the response Connect provides a parameter called "debugResponse" in the following methods

```swift
public func request(_ request: Connector, debugResponse: Bool = false) -> Future<Data>
public func upload(files: [File]?, to request: Connector, debugResponse: Bool = false) -> Future<Data>
```
If you flip the switch and toggle debugResponse to true (it's defaulted to false) the entire response will be printed to the console whether it's success or failure allowing for a better visibility when debugging.

For example calling
```swift
Connect.default.request(TodoConnector.get(id: 123), debugResponse: true).decoded(toType: Todo.self)
```

Will result into the following output to the console
```bash
$ curl -v \
    -X GET \
    -b "__cfduid=d28ba4711e524514d5211ca1973b297f51589810370" \
    -H "Accept-Encoding: br;q=1.0, gzip;q=0.9, deflate;q=0.8" \
    -H "Accept-Language: en-US;q=1.0, ar-US;q=0.9, en;q=0.8" \
    -H "User-Agent: Connect Example/1.0 (com.connect.example; build:1; iOS 13.3.0) Alamofire/5.1.0" \
    "https://jsonplaceholder.typicode.com/todos/123"
=======================================
{
  "id" : 123,
  "title" : "esse et quis iste est earum aut impedit",
  "userId" : 7,
  "completed" : false
}
```
