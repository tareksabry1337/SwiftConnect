//
//  MimeType.swift
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

public struct MimeType: RawRepresentable, Equatable, Hashable {

    static public let jpg = MimeType(rawValue: "image/jpeg")
    static public let png = MimeType(rawValue: "image/png")
    static public let gif = MimeType(rawValue: "image/gif")
    static public let tiff = MimeType(rawValue: "image/tiff")
    static public let mp4 = MimeType(rawValue: "video/mp4")
    static public let pdf = MimeType(rawValue: "application/pdf")
    static public let mov = MimeType(rawValue: "video/quicktime")
    static public let binary = MimeType(rawValue: "application/octet-stream")

    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}
