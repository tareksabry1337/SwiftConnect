//
//  URLExtension.swift
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

extension URL {

    func withPathParameters(pattern: String, parameters: [String: Any]?) -> URL {
        guard
            let parameters = parameters,
            var urlSafePattern = pattern.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        else {
            return self
        }
        
        var urlString = absoluteString
        
        for parameter in parameters {
            urlSafePattern = urlSafePattern.replacingOccurrences(of: "key", with: parameter.key)
            urlString = urlString.replacingOccurrences(of: urlSafePattern, with: "\(parameter.value)")
        }

        guard let url = URL(string: urlString) else { return self }
        return url
    }

    func withPathParameter(pattern: String, _ key: String, value: Any) -> URL {
        guard
            var urlSafePattern = pattern.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        else {
            return self
        }
        
        var urlString = absoluteString
        
        urlSafePattern = pattern.replacingOccurrences(of: "key", with: key)
        urlString = urlString.replacingOccurrences(of: urlSafePattern, with: "\(value)")

        guard let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)) else { return self }
        return url
    }

}

