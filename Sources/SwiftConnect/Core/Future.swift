//
//  Future.swift
//
//  Copyright (c) 2017 John Sundell
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

open class Future<Value> {

    var result: Swift.Result<Value, Error>? {
        didSet { result.map(report) }
    }

    private lazy var callbacks = [(Swift.Result<Value, Error>) -> Void]()

    fileprivate let requestIdentifier: String

    init(requestIdentifier: String) {
        self.requestIdentifier = requestIdentifier
    }

    public func observe(with callback: @escaping (Swift.Result<Value, Error>) -> Void) {
        callbacks.append(callback)
        result.map(callback)
    }

    private func report(result: Swift.Result<Value, Error>) {
        for callback in callbacks {
            callback(result)
        }
    }

}

public extension Future {
    func chained<NextValue>(with closure: @escaping (Value) throws -> Future<NextValue>) -> Future<NextValue> {
        let promise = Promise<NextValue>(requestIdentifier: requestIdentifier)

        observe { result in
            switch result {
            case .success(let value):
                do {
                    let future = try closure(value)

                    future.observe { result in
                        switch result {
                        case .success(let value):
                            promise.resolve(with: value)
                        case .failure(let error):
                            promise.reject(with: error)
                        }
                    }
                } catch {
                    promise.reject(with: error)
                }
            case .failure(let error):
                promise.reject(with: error)
            }
        }

        return promise
    }

    func transformed<NextValue>(with closure: @escaping (Value) throws -> NextValue) -> Future<NextValue> {
        let requestIdentifier = self.requestIdentifier
        return chained { value in
            return try Promise(value: closure(value), requestIdentifier: requestIdentifier)
        }
    }
}

public extension Future {

    func cancel() {
        NotificationCenter.default.post(name: .cancelRequest, object: nil, userInfo: [
            "requestIdentifier": requestIdentifier
        ])
    }

}
