//
//  JSONDecoderExtension.swift
//
//  Copyright (c) 2017 Alexandr Goncharov
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

public extension JSONDecoder {

    /// Decode value at the keypath of the given type from the given JSON representation
    ///
    /// - Parameters:
    ///   - type: The type of the value to decode.
    ///   - data: The data to decode from.
    ///   - keyPath: The JSON keypath
    ///   - keyPathSeparator: Nested keypath separator
    /// - Returns: A value of the requested type.
    /// - Throws: An error if any value throws an error during decoding.
    func decode<T>(
        _ type: T.Type,
        from data: Data,
        keyPath: String,
        keyPathSeparator separator: String = "."
    ) throws -> T where T: Decodable {
        userInfo[keyPathUserInfoKey] = keyPath.components(separatedBy: separator)
        return try decode(KeyPathWrapper<T>.self, from: data).object
    }

    func decodeIfPresent<T>(
        _ type: T.Type,
        from data: Data,
        keyPath: String,
        keyPathSeparator separator: String = "."
    ) -> T? where T: Decodable {
        userInfo[keyPathUserInfoKey] = keyPath.components(separatedBy: separator)
        return try? decode(KeyPathWrapper<T>.self, from: data).object
    }
}

public extension JSONDecoder {

    static var snakeCaseDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }

}

/// The keypath key in the `userInfo`
private let keyPathUserInfoKey = CodingUserInfoKey(rawValue: "keyPathUserInfoKey")! // swiftlint:disable:this force_unwrapping line_length

/// Object which is representing value
private final class KeyPathWrapper<T: Decodable>: Decodable {

    enum KeyPathError: Error {
        case `internal`
    }

    /// Naive coding key implementation
    struct Key: CodingKey {
        init?(intValue: Int) {
            self.intValue = intValue
            stringValue = String(intValue)
        }

        init?(stringValue: String) {
            self.stringValue = stringValue
            intValue = nil
        }

        let intValue: Int?
        let stringValue: String
    }

    typealias KeyedContainer = KeyedDecodingContainer<KeyPathWrapper<T>.Key>

    init(from decoder: Decoder) throws {
        guard let keyPath = decoder.userInfo[keyPathUserInfoKey] as? [String],
            !keyPath.isEmpty
            else { throw KeyPathError.internal }

        /// Creates a `Key` from the first keypath element
        func getKey(from keyPath: [String]) throws -> Key {
            guard let first = keyPath.first,
                let key = Key(stringValue: first)
                else { throw KeyPathError.internal }
            return key
        }

        /// Finds nested container and returns it and the key for object
        func objectContainer(for keyPath: [String],
                             in currentContainer: KeyedContainer,
                             key currentKey: Key) throws -> (KeyedContainer, Key) {
            guard !keyPath.isEmpty else { return (currentContainer, currentKey) }
            let container = try currentContainer.nestedContainer(keyedBy: Key.self, forKey: currentKey)
            let key = try getKey(from: keyPath)
            return try objectContainer(for: Array(keyPath.dropFirst()), in: container, key: key)
        }

        let rootKey = try getKey(from: keyPath)
        let rooTContainer = try decoder.container(keyedBy: Key.self)
        let (keyedContainer, key) = try objectContainer(
            for: Array(keyPath.dropFirst()),
            in: rooTContainer, key: rootKey
        )
        object = try keyedContainer.decode(T.self, forKey: key)
    }

    let object: T
}
