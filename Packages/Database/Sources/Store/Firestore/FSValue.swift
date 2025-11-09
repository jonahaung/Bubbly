//
//  FSValue.swift
//  Database
//
//  Created by Aung Ko Min on 28/10/25.
//

import Foundation

//
//  FSValue.swift
//  Database
//
//  Created by Aung Ko Min on 28/10/25.
//

public enum FSValue: Codable, Sendable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case timestamp(Date)
    case map([String: FSValue])
    case array([FSValue])
    case null

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .string(stringValue):
            try container.encode(stringValue, forKey: .stringValue)
        case let .int(intValue):
            try container.encode("\(intValue)", forKey: .integerValue)
        case let .double(doubleValue):
            try container.encode(doubleValue, forKey: .doubleValue)
        case let .bool(boolValue):
            try container.encode(boolValue, forKey: .booleanValue)
        case let .timestamp(date):
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            try container.encode(formatter.string(from: date), forKey: .timestampValue)
        case let .map(dict):
            var mapContainer = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .mapValue)
            try mapContainer.encode(FSMap(fields: dict), forKey: .fields)
        case let .array(arr):
            var arrContainer = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .arrayValue)
            try arrContainer.encode(FSArray(values: arr), forKey: .values)
        case .null:
            try container.encodeNil(forKey: .nullValue)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let stringValue = try? container.decode(String.self, forKey: .stringValue) {
            self = .string(stringValue)
        } else if let intString = try? container.decode(String.self, forKey: .integerValue), let intVal = Int(intString) {
            self = .int(intVal)
        } else if let doubleValue = try? container.decode(Double.self, forKey: .doubleValue) {
            self = .double(doubleValue)
        } else if let boolValue = try? container.decode(Bool.self, forKey: .booleanValue) {
            self = .bool(boolValue)
        } else if let timestamp = try? container.decode(String.self, forKey: .timestampValue),
                  let date = formatter.date(from: timestamp)
        {
            self = .timestamp(date)
        } else if container.contains(.mapValue) {
            let mapContainer = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .mapValue)
            let fsMap = try mapContainer.decode(FSMap.self, forKey: .fields)
            self = .map(fsMap.fields)
        } else if container.contains(.arrayValue) {
            let arrContainer = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .arrayValue)
            let fsArray = try arrContainer.decode(FSArray.self, forKey: .values)
            self = .array(fsArray.values)
        } else if container.contains(.nullValue) {
            self = .null
        } else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath,
                      debugDescription: "Unknown Firestore value type")
            )
        }
    }

    private enum CodingKeys: String, CodingKey {
        case stringValue
        case integerValue
        case doubleValue
        case booleanValue
        case timestampValue
        case mapValue
        case fields
        case arrayValue
        case values
        case nullValue
    }

    struct FSMap: Codable, Sendable {
        let fields: [String: FSValue]
    }

    struct FSArray: Codable, Sendable {
        let values: [FSValue]
    }
}

public struct FSDocument: Codable, Sendable {
    public let fields: [String: FSValue]
}
