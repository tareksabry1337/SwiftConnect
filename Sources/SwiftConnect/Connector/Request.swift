//
//  Request.swift
//
//  Copyright (c) 2020 Tarek Sabry
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

public typealias HTTPMethod = Alamofire.HTTPMethod
public typealias HTTPHeader = Alamofire.HTTPHeader

public protocol Requestable: Alamofire.URLRequestConvertible {
    var baseURL: URL { get }
    var endpoint: String { get }
    var method: HTTPMethod { get }
}

extension Requestable {
    
    public func asURLRequest() throws -> URLRequest {
        let url: URL
        
        if endpoint.isEmpty {
            url = baseURL
        } else {
            url = baseURL.appendingPathComponent(endpoint)
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue

        if let authorizedConnector = self as? AuthorizedRequest, let token = authorizedConnector.authorizationToken {
            switch token {
            case .bearer(let token):
                urlRequest.headers.add(.authorization(bearerToken: token))
            case .basic(let username, let password):
                urlRequest.headers.add(.authorization(username: username, password: password))
            case .custom(let key, let token):
                urlRequest.headers.add(.init(name: key, value: token))
            }
        }
        
        Mirror(reflecting: self).children.forEach { _, value in
            if let header = value as? Header {
                urlRequest.headers.add(header.projectedValue)
            }
        }
        
        return try encode(request: urlRequest)
    }
    
    private func encode(request: URLRequest) throws -> URLRequest {
        var request = request
        
        try Mirror(reflecting: self).children.forEach { _, value in
            if let parameter = value as? StringParameter {
                request = try parameter.encoding.encode(request, with: [parameter.key: parameter.value])
            }
            
            if let parameter = value as? EncodableParameter {
                request = try parameter.encodeParameters(into: request)
            }
            
            if let parameter = value as? RawData {
                request.httpBody = parameter.value
            }
        }
        
        return request
    }
    
}

public protocol Request: Requestable {
    
}
