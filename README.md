# SwiftConnect

## What is SwiftConnect?

SwiftConnect is a lightweight network abstraction layer, built on top of Alamofire. It can be used to dramatically simplify interacting with RESTful JSON web-services.

## Table of contents

- [Why should I use SwiftConnect and not any other abstraction layer?](https://github.com/tareksabry1337/SwiftConnect/blob/main/Documentation/Why%20use%20SwiftConnect.md)
- [Transformers](https://github.com/tareksabry1337/SwiftConnect/blob/main/Documentation//Transformers.md)
    - [Codable Transformer](https://github.com/tareksabry1337/SwiftConnect/blob/main/Documentation/Transformers.md#Codable-Transformer)
    - [Dictionary Transformer](https://github.com/tareksabry1337/SwiftConnect/blob/main/Documentation/Transformers.md#Dictionary-Transformer)
    - [Void Transformer](https://github.com/tareksabry1337/SwiftConnect/blob/main/Documentation/Transformers.md#Void-Transformer)
    - [Creating your own transformer](https://github.com/tareksabry1337/SwiftConnect/blob/main/Documentation/Transformers.md#Creating-your-own-transformer)
- [Usage](https://github.com/tareksabry1337/SwiftConnect/blob/main/Documentation/Usage.md)
    - [How to use SwiftConnect?](https://github.com/tareksabry1337/SwiftConnect/blob/main/Documentation/Usage.md#How-to-use-SwiftConnect)
    - [Connect](https://github.com/tareksabry1337/SwiftConnect/blob/main/Documentation/Usage.md#Connect)
    - [Connect Middleware](https://github.com/tareksabry1337/SwiftConnect/blob/main/Documentation/Usage.md#ConnectMiddleware)
    - [Error Handler](https://github.com/tareksabry1337/SwiftConnect/blob/main/Documentation/Usage.md#ErrorHandler)
    - [Requestable](https://github.com/tareksabry1337/SwiftConnect/blob/main/Documentation/Usage.md#Requestable)
    - [Available propertyWarppers](https://github.com/tareksabry1337/SwiftConnect/blob/main/Documentation/Usage.md#Available-propertyWrappers)
    - [What is `@Query`?](https://github.com/tareksabry1337/SwiftConnect/blob/main/Documentation/Usage.md#What-is-query)
    - [What is `@Path`?](https://github.com/tareksabry1337/SwiftConnect/blob/main/Documentation/Usage.md#What-is-path)
    - [What is `@RawData`?](https://github.com/tareksabry1337/SwiftConnect/blob/main/Documentation/Usage.md#What-is-rawdata)
    - [What is `@Object`?](https://github.com/tareksabry1337/SwiftConnect/blob/main/Documentation/Usage.md#What-is-object)
    - [What is `@Header`?](https://github.com/tareksabry1337/SwiftConnect/blob/main/Documentation/Usage.md#What-is-header)
    - [Creating Complex Request](https://github.com/tareksabry1337/SwiftConnect/blob/main/Documentation/Usage.md#creating-complex-request)
    - [AuthorizedRequest](https://github.com/tareksabry1337/SwiftConnect/blob/main/Documentation/Usage.md#AuthorizedRequest)
    - [File](https://github.com/tareksabry1337/SwiftConnect/blob/main/Documentation/Usage.md#File)
    - [Using Connect](https://github.com/tareksabry1337/SwiftConnect/blob/main/Documentation/Usage.md#Using-Connect)
    - [Module](https://github.com/tareksabry1337/SwiftConnect/blob/main/Documentation/Usage.md#Module)
    - [Building Modules](https://github.com/tareksabry1337/SwiftConnect/blob/main/Documentation/Usage.md#Building-Modules)
    - [Cancelling Requests](https://github.com/tareksabry1337/SwiftConnect/blob/main/Documentation/Usage.md#Cancelling-Requests)
- [Debugging](https://github.com/tareksabry1337/SwiftConnect/blob/main/Documentation/Debugging.md)

## Requirements

- iOS 13.0+
- Xcode 13.2+
- Swift 5.5+

## Installation

SwiftConnect is available through Swift Package Manager To install
it, simply add the following line to your Package.swift:

```swift
dependencies: [
    .package(url: "https://github.com/tareksabry1337/SwiftConnect.git", .upToNextMajor(from: "3.0.0"))
]
```

## Previous Versions

SwiftConnect has move away from all closure based code and is now completely implemented using Swift's new shiny async / await, if you are still interested in the legacy version that supports iOS 10.0 please refer to the v2 branch instead for the documentation and installation

## Support

Please, don't hesitate to [file an issue](https://github.com/tareksabry1337/SwiftConnect/issues/new) if you have questions.

## What's Next ?
- [ ] Unit Testing
- [ ] OAuth2 Support
- [ ] Support for downloading tasks
- [ ] Support for handling refresh tokens.

## Dependncies
SwiftConnect doesn't have any depedency except Alamofire

[Alamofire]: https://github.com/Alamofire/Alamofire

Everything else was built from scratch natively and using Swift's Modern APIs

## License

SwiftConnect is available under the MIT license. See the LICENSE file for more info.
