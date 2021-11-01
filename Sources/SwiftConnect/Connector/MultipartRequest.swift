//
//  MultipartRequest.swift
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

public protocol MultipartRequest: Requestable {
    var files: [File] { get }
    var parameters: [String: Any] { get }
}

public extension MultipartRequest {
    
    var parameters: [String: Any] {
        var parameters: [String: Any]? = [:]
        
        Mirror(reflecting: self).children.forEach { _, value in
            if let parameter = value as? EncodableParameter {
                
                if let encoding = parameter.encoding as? URLEncoding, encoding.destination == .httpBody {
                    parameters = try? parameter.value?.asDictionary(using: parameter.encoder)
                }
                
                if parameter.encoding is JSONEncoding {
                    parameters = try? parameter.value?.asDictionary(using: parameter.encoder)
                }
            }
        }
        
        return parameters ?? [:]
    }
    
}
