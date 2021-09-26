## Why should I use SwiftConnect and not any other abstraction layer ?

- [x] Generic, protocol-based implementation
- [x] Built-in response and error parsing
- [x] Out of the box support for parsing (Codable) 
- [x] Support for upload tasks

But that's not really where SwiftConnect shines, at its core it's very simple but the exposed APIs are very powerful what differs SwiftConnect from any other library

- [x] Path Parameters support
- [x] Powerful chaining based on Futures / Promises

#### What are futures / promises ?

- A Promise is something you make to someone else.
- In the Future you may choose to honor (resolve) that promise, or reject it.

If we use the above definition, Futures and Promises become two sides of the same coin. A promise gets constructed, then returned as a future, where it can be used to extract information at a later point.

#### How does SwiftConnect benefit from this concept ?

First thing first SwiftConnect returns plain "Data" from the request it, unlike any other networking abstraction layer SwiftConnect never assumes the data type you want and it leaves the decision up to you whether you want it as plain Data / Convert it to Codable model / Convert it to a dictionary or whatever you want to do with this data.

This is what I call [**Transformers**](https://github.com/tareksabry1337/SwiftConnect/blob/master/Transformers.md)
