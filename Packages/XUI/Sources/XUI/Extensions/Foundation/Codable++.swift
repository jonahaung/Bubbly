//
//  Codable++.swift
//  MsgRoom
//
//  Created by Aung Ko Min on 7/4/24.
//

import Foundation

public extension Encodable {
    var dictionary: [String: Any] {
		let encoder = JSONEncoder()
		encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
		guard let data = try? encoder.encode(self) else { return [:] }
        return (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)).flatMap { $0 as? [String: Any] } ?? [:]
    }
    var jsonData: Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
		encoder.keyEncodingStrategy = .convertToSnakeCase
        return try? encoder.encode(self)
    }
    var preetyPrinted: String {
        if let jsonData {
            return String(data: jsonData, encoding: .utf8) ?? "Error"
        }
        return "Error"
    }
}
