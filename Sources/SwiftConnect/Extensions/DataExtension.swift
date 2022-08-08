//
//  DataExtension.swift
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

extension Data {

    var prettyPrintedJSONString: NSString? {
        guard let object = try? JSONSerialization.jsonObject(with: self, options: []),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
              let prettyPrintedString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else {
                return NSString(string: String(data: self, encoding: .utf8) ?? "")
        }

        return prettyPrintedString
    }

    enum ContentType: String {
        case jpg
        case png
        case gif
        case tiff
        case unknown

        var fileExtension: String {
            return rawValue
        }

        var mimeType: MimeType {
            switch self {
            case .jpg:
                return .jpg
            case .png:
                return .png
            case .gif:
                return .gif
            case .tiff:
                return .tiff
            case .unknown:
                return .binary
            }
        }
    }

    var contentType: ContentType {
        var values = [UInt8](repeating: 0, count: 1)

        copyBytes(to: &values, count: 1)

        switch values[0] {
        case 0xFF:
            return .jpg
        case 0x89:
            return .png
        case 0x47:
            return .gif
        case 0x49, 0x4D :
            return .tiff
        default:
            return .unknown
        }
    }

}
