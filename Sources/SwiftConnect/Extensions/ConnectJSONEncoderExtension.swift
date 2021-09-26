//
//  ConnectJSONEncoderExtension.swift
//  Starr Power
//
//  Created by Tarek Sabry on 01/04/2021.
//

import Foundation

public extension JSONEncoder {

    static var snakeCaseEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }

}
