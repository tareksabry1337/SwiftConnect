//
//  Connect.swift
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

public protocol ErrorHandlerProtocol {
    func handle(response: [String: Any], statusCode: Int) throws
}

open class ErrorHandler: ErrorHandlerProtocol {
    
    public func handle(response: [String: Any], statusCode: Int) throws {
        let message: String
        if let error = response["msg"] as? String {
            message = error
        } else if let error = response["message"] as? String {
            message = error
        } else if let error = response["error"] as? String {
            message = error
        } else if let error = response["err"] as? String {
            message = error
        } else {
            message = "Something went wrong"
        }
        
        throw NSError(domain: "", code: statusCode, userInfo: [
            NSLocalizedDescriptionKey: message
        ])
    }
    
    public init() {}
}

public final class Connect {
    
    private let middleware: ConnectMiddlewareProtocol
    private let errorHandler: ErrorHandlerProtocol
    
    private lazy var session: Session = middleware.session
    
    public static let `default`: Connect = Connect()
    
    public var isLoggingEnabled: Bool
    
    public init(
        middleware: ConnectMiddlewareProtocol = ConnectMiddleware(),
        errorHandler: ErrorHandlerProtocol = ErrorHandler(),
        isLoggingEnabled: Bool = true
    ) {
        self.middleware = middleware
        self.errorHandler = errorHandler
        self.isLoggingEnabled = isLoggingEnabled
    }
    
    private func parseResponse(response: AFDataResponse<Data>) throws {
        
        if case .some(AFError.explicitlyCancelled) = response.error {
            return
        }
        
        if case .failure(let errorResult) = response.result {
            if case .sessionTaskFailed(let error) = errorResult {
                switch error.code {
                case URLError.dataNotAllowed.rawValue, URLError.notConnectedToInternet.rawValue:
                    throw ConnectError.notConnectedToInternet
                    
                case URLError.timedOut.rawValue:
                    throw ConnectError.timedOut
                    
                default:
                    throw ConnectError.internalServerError
                }
            }
        }
        
        let statusCode = response.response?.statusCode ?? 0
        
        if (200 ..< 300).contains(statusCode) == false {
            guard
                let response = try? JSONSerialization.jsonObject(
                    with: response.data ?? Data(),
                    options: []
                ) as? [String: AnyObject]
            else {
                throw ConnectError.internalServerError
            }
            
            return try errorHandler.handle(response: response, statusCode: statusCode)
        }
    }
    
    public func makeDataTask(request: Requestable) -> DataTask<Data> {
        return session
            .request(request)
            .cURLDescription(calling: debugLog)
            .serializingData()
    }
    
    public func makeUploadTask(request: Requestable) -> DataTask<Data> {
        guard
            let multipartRequest = request as? MultipartRequest
        else {
            fatalError("Incorrect request type passed to function, expected type \(MultipartRequest.self), found \(type(of: request))")
        }
        
        let multipartFormData = MultipartFormData()
        
        multipartRequest.files.forEach { file in
            multipartFormData.append(
                file.data,
                withName: file.key,
                fileName: file.name,
                mimeType: file.mimeType.rawValue
            )
        }
        
        multipartRequest.parameters.forEach { parameter in
            multipartFormData.append("\(parameter.value)".data(using: .utf8) ?? Data(), withName: parameter.key)
        }
        
        return session
            .upload(multipartFormData: multipartFormData, with: multipartRequest)
            .cURLDescription(calling: debugLog)
            .serializingData()
    }
    
    public func execute(task: DataTask<Data>, debugResponse: Bool = false) async throws -> Response {
        let response = await task.response

        if isLoggingEnabled && debugResponse {
            log(response: response)
        }
        
        return try createResponse(from: response)
    }
    
    public func request(request: Requestable, debugResponse: Bool = false) async throws -> Response {
        let dataTask = makeDataTask(request: request)
        return try await execute(task: dataTask, debugResponse: debugResponse)
    }
    
    public func request(
        multipartRequest: Requestable,
        debugResponse: Bool = false
    ) async throws -> Response {
        let uploadTask = makeUploadTask(request: multipartRequest)
        return try await execute(task: uploadTask, debugResponse: debugResponse)
    }
    
    private func log(response: DataResponse<Data, AFError>) {
        let statusCode = response.response?.statusCode ?? 0
        let url = response.request?.url?.absoluteString ?? ""
        let elapsedTime = response.metrics?.taskInterval.duration ?? 0.0
        print("\(statusCode) '\(url)' [\(String(format: "%.04f", elapsedTime)) s]:")
        print((response.data ?? Data()).prettyPrintedJSONString ?? "")
    }
    
    private func createResponse(from response: DataResponse<Data, AFError>) throws -> Response {
        try parseResponse(response: response)
        
        switch response.result {
        case .success(let data):
            guard
                let request = response.request,
                let httpURLResponse = response.response
            else {
                throw ConnectError.internalServerError
            }
            
            let response = Response(
                request: request,
                response: httpURLResponse,
                data: data
            )
            
            return response
            
        case .failure(let error):
            throw error
        }
    }
    
    public func cancelAllRequests() {
        session.cancelAllRequests()
    }
    
    private func debugLog(description: String) {
        if isLoggingEnabled {
            print("=======================================")
            print(description)
            print("=======================================")
        }
    }
    
}
