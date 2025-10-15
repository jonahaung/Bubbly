//
//  OpaqueValue.swift
//  OpaqueValue
//
//  Created by Thomas Asheim Smedmann on 14/07/2024.
//

import Foundation

public enum OpaqueValue: Equatable {
	public struct PropertyKey: CodingKey, Hashable {
		public var stringValue: String
		public var intValue: Int?

		public init?(stringValue: String) {
            self.stringValue = stringValue
        }

		public init?(intValue: Int) {
            self.intValue = intValue
            self.stringValue = String(intValue)
        }
    }

    case object([PropertyKey: OpaqueValue])
    case array([OpaqueValue])
    case string(String)
    case number(Double)
    case boolean(Bool)
    case null
}

extension OpaqueValue: Encodable {
	public func encode(to encoder: any Encoder) throws {
        switch self {
            case .object(let values):
                var container = encoder.container(keyedBy: PropertyKey.self)
                for (key, value) in values {
                    try container.encode(value, forKey: key)
                }
            case .array(let values):
                var container = encoder.unkeyedContainer()
                for value in values {
                    try container.encode(value)
                }
            case .string(let value):
                var container = encoder.singleValueContainer()
                try container.encode(value)
            case .number(let value):
                var container = encoder.singleValueContainer()
                try container.encode(value)
            case .boolean(let value):
                var container = encoder.singleValueContainer()
                try container.encode(value)
            case .null:
                var container = encoder.singleValueContainer()
                try container.encodeNil()
        }
    }
}

// MARK: OpaqueValue+Decodable

extension OpaqueValue: Decodable {
	public init(from decoder: any Decoder) throws {
        if let container = try? decoder.container(keyedBy: PropertyKey.self) {
            var values: [PropertyKey: OpaqueValue] = [:]
            for key in container.allKeys {
                values[key] = try container.decode(OpaqueValue.self, forKey: key)
            }
            self = .object(values)
        } else if var container = try? decoder.unkeyedContainer() {
            var values: [OpaqueValue] = []
            while !container.isAtEnd {
                values.append(try container.decode(OpaqueValue.self))
            }
            self = .array(values)
        } else {
            let container = try decoder.singleValueContainer()
            if let value = try? container.decode(String.self) {
                self = .string(value)
            } else if let value = try? container.decode(Double.self) {
                self = .number(value)
            } else if let value = try? container.decode(Bool.self) {
                self = .boolean(value)
            } else {
                guard container.decodeNil() else {
                    throw DecodingError.dataCorruptedError(in: container, debugDescription: "Data unrecognizable")
                }
                self = .null
            }
        }
    }
}
/// *
// 
// // Sample JSON-like data represented using OpaqueValue
// let data: OpaqueValue = .object([
//     "name": .string("Alice"),
//     "age": .number(25),
//     "isActive": .boolean(true),
//     "scores": .array([.number(92.5), .number(88.0), .number(79.5)]),
//     "address": .object([
//         "street": .string("123 Swift Lane"),
//         "city": .string("Cupertino"),
//         "zip": .number(95014)
//     ]),
//     "metadata": .null
// ])
//
// // Encoding to JSON
// let encoder = JSONEncoder()
// encoder.outputFormatting = .prettyPrinted // For readability
//
// if let jsonData = try? encoder.encode(data),
//    let jsonString = String(data: jsonData, encoding: .utf8) {
//     print("Encoded JSON:\n\(jsonString)")
// }
//
// // Decoding from JSON
// let decoder = JSONDecoder()
// if let decodedData = try? decoder.decode(OpaqueValue.self, from: jsonData) {
//     print("\nDecoded OpaqueValue:\n\(decodedData)")
// }
// */
