## Why should I use SwiftConnect and not any other abstraction layer ?

- [x] Generic, protocol-based implementation
- [x] Built-in response and error parsing
- [x] Out of the box support for parsing (Codable) 
- [x] Support for upload tasks

But that's not really where SwiftConnect shines, at its core it's very simple but the exposed APIs are very powerful what differs SwiftConnect from any other library

- [x] Expressive in parameters (Think retrofit)
- [x] Path Parameters support
- [x] Powerful chaining based on async / await

#### How does SwiftConnect get its power from async / await ?

First thing first SwiftConnect returns plain `Response` type from the request, unlike any other networking abstraction layer SwiftConnect never assumes the data type you want and it leaves the decision up to you whether you want it as plain Response / Convert it to Codable model / Convert it to a dictionary or whatever you want to do with this data.

The `Response` object is composed of the following parameters:
 - `request` which is the original URLRequest
 - `statusCode` which is the result status code of the network call
 - `headers` which are the headers that's returned with the network call
 - `data` which is the plain data returned from the object used for transformeration opretaions
 
 And since we now know that there's no assumption for the returned response a few handy `Transformers` have been created in order to convert from `Response` type to different things (Codable / String / Dictionary..)

Check this link for more information about [**Transformers**](https://github.com/tareksabry1337/SwiftConnect/blob/master/Transformers.md)
