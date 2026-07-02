//
//  Codable+Extensions.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import Foundation

public extension Decodable {
    static func fromDictionary(_ dictionary: [String: Any]) throws -> Self {
        let data = try JSONSerialization.data(withJSONObject: dictionary)
        return try JSONDecoder().decode(Self.self, from: data)
    }
}

public extension Encodable {
    func asDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        let object = try JSONSerialization.jsonObject(with: data)

        guard let dictionary = object as? [String: Any] else {
            throw NSError(
                domain: "Encodable+Dictionary",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey: "Top-level JSON is not a dictionary."
                ]
            )
        }

        return dictionary
    }

    var dictionary: [String: Any] {
        (try? asDictionary()) ?? [:]
    }

    var jsonData: Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [
            .prettyPrinted,
            .sortedKeys,
            .withoutEscapingSlashes
        ]
        return try? encoder.encode(self)
    }

    var prettyPrinted: String {
        jsonData.flatMap { String(data: $0, encoding: .utf8) } ?? "Error"
    }
}

public extension Encodable where Self: Decodable {
    func copyMatchingProperties<T: Encodable>(from other: T) throws -> Self {
        var currentDict = try asDictionary()
        let otherDict = try other.asDictionary()

        for key in currentDict.keys where otherDict[key] != nil {
            currentDict[key] = otherDict[key]
        }

        return try Self.fromDictionary(currentDict)
    }
}
