//
//  AuthorizedRequest.swift
//
//  Copyright (c) 2021 Tarek Sabry
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation
import Alamofire

@propertyWrapper
struct Object<T: Encodable> {
    var value: Encodable?
    var encoder: JSONEncoder
    var encoding: ParameterEncoding
    
    var wrappedValue: T {
        get {
            guard let value = value as? T else {
                fatalError("Undefined object in request, must pass value for the encodable object")
            }
            
            return value
        } set {
            value = newValue
        }
    }
    
    init(encoder: JSONEncoder = JSONEncoder(), encoding: ParameterEncoding) {
        self.encoder = encoder
        self.encoding = encoding
    }
}

extension Object: EncodableParameter {
    
    func encodeParameters(into request: URLRequest) throws -> URLRequest {
        if wrappedValue is Array<Any> {
            var request = request
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try wrappedValue.asData(using: encoder)
            return request
        } else {
            return try encoding.encode(request, with: wrappedValue.asDictionary(using: encoder))
        }
    }
    
}
