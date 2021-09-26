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
    func handle(response: [String: Any], statusCode: Int) -> Error?
}

open class ErrorHandler: ErrorHandlerProtocol {
    
    public func handle(response: [String: Any], statusCode: Int) -> Error? {
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
        
        return NSError(domain: "", code: statusCode, userInfo: [
            NSLocalizedDescriptionKey: message
        ])
    }
    
    public init() {}
}

public final class Connect {
    
    private let middleware: ConnectMiddlewareProtocol
    private let errorHandler: ErrorHandlerProtocol
    
    private lazy var session: Session = middleware.session
    
    private var cancellables = [String: DataRequest]()
    
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
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(cancelRequest(_:)),
            name: .cancelRequest,
            object: nil
        )
    }
    
    private func parseResponse(response: AFDataResponse<Data>) -> Error? {
        
        if case .some(AFError.explicitlyCancelled) = response.error {
            return nil
        }
        
        if case .failure(let errorResult) = response.result {
            if case .sessionTaskFailed(let error) = errorResult {
                switch error.code {
                case URLError.dataNotAllowed.rawValue, URLError.notConnectedToInternet.rawValue:
                    return ConnectError.notConnectedToInternet
                    
                case URLError.timedOut.rawValue:
                    return ConnectError.timedOut
                    
                default:
                    return ConnectError.internalServerError
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
                return ConnectError.internalServerError
            }
            
            return errorHandler.handle(response: response, statusCode: statusCode)
        }
        
        return nil
    }
    
    public func request(request: Requestable, debugResponse: Bool = false) -> Future<Response> {
        let dataRequest = session.request(request).cURLDescription(calling: debugLog)
        let promise = Promise<Response>(requestIdentifier: dataRequest.id.uuidString)
        
        dataRequest.validate().responseData { [weak self] response in
            guard let self = self else { return }
            
            if self.isLoggingEnabled && debugResponse {
                let statusCode = response.response?.statusCode ?? 0
                let url = response.request?.url?.absoluteString ?? ""
                let elapsedTime = response.metrics?.taskInterval.duration ?? 0.0
                print("\(statusCode) '\(url)' [\(String(format: "%.04f", elapsedTime)) s]:")
                print((response.data ?? Data()).prettyPrintedJSONString ?? "")
            }
            
            if let error = self.parseResponse(response: response) {
                promise.reject(with: error)
                return
            }
            
            switch response.result {
            case .success(let data):
                
                guard let request = response.request, let httpURLResponse = response.response else {
                    promise.reject(with: ConnectError.internalServerError)
                    return
                }
                
                let response = Response(request: request, response: httpURLResponse, data: data)
                promise.resolve(with: response)
                
            case .failure(let error):
                promise.reject(with: error)
            }
        }
        
        cancellables[dataRequest.id.uuidString] = dataRequest
        
        return promise
    }
    
    public func request(
        multipartRequest: Requestable,
        debugResponse: Bool = false,
        progressHandler: Alamofire.Request.ProgressHandler? = nil
    ) -> Future<Response> {
        guard
            let multipartRequest = multipartRequest as? MultipartRequest
        else {
            fatalError("Incorrect request type passed to function, expected type \(MultipartRequest.self), found \(type(of: multipartRequest))")
        }
        
        let uploadRequest = session.upload(multipartFormData: { formData in
            
            multipartRequest.files.forEach { file in
                formData.append(
                    file.data,
                    withName: file.key,
                    fileName: file.name,
                    mimeType: file.mimeType.rawValue
                )
            }
            
            multipartRequest.parameters.forEach { parameter in
                formData.append("\(parameter.value)".data(using: .utf8) ?? Data(), withName: parameter.key)
            }
            
        }, with: multipartRequest)
        
        if let progressHandler = progressHandler {
            uploadRequest.uploadProgress(queue: .main, closure: progressHandler)
        }
        
        let promise = Promise<Response>(requestIdentifier: uploadRequest.id.uuidString)
        
        uploadRequest.cURLDescription(calling: debugLog).validate().responseData { [weak self] response in
            guard let self = self else { return }
            
            if self.isLoggingEnabled && debugResponse {
                let statusCode = response.response?.statusCode ?? 0
                let url = response.request?.url?.absoluteString ?? ""
                let elapsedTime = response.metrics?.taskInterval.duration ?? 0.0
                print("\(statusCode) '\(url)' [\(String(format: "%.04f", elapsedTime)) s]:")
                print((response.data ?? Data()).prettyPrintedJSONString ?? "")
            }
            
            if let error = self.parseResponse(response: response) {
                promise.reject(with: error)
                return
            }
            
            switch response.result {
            case .success(let data):
                
                guard let request = response.request, let httpURLResponse = response.response else {
                    promise.reject(with: ConnectError.internalServerError)
                    return
                }
                
                let response = Response(request: request, response: httpURLResponse, data: data)
                promise.resolve(with: response)
                
            case .failure(let error):
                promise.reject(with: error)
            }
        }
        
        cancellables[uploadRequest.id.uuidString] = uploadRequest
        
        return promise
    }
    
    public func cancelAllRequests() {
        session.cancelAllRequests()
    }
    
    @objc private func cancelRequest(_ notification: NSNotification) {
        guard let requestIdentifier = notification.userInfo?["requestIdentifier"] as? String else { return }
        cancellables[requestIdentifier]?.cancel()
        cancellables[requestIdentifier] = nil
    }
    
    private func debugLog(description: String) {
        if isLoggingEnabled {
            print("=======================================")
            print(description)
            print("=======================================")
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
