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
		encoder.dateEncodingStrategy = .millisecondsSince1970
        return try? encoder.encode(self)
    }
    var preetyPrinted: String {
        if let jsonData {
            let preety = String(data: jsonData, encoding: .utf8) ?? "Error"
			var lines = [String]()
			let s =
"""
"
"""
			preety.lines().forEach { line in
				let parts = line.components(separatedBy: ":")
				if parts.count == 2 {
					let key = parts[0]
					let value = parts[1]
					let newLine = "-\(key)\n\(value)".replace(s, with: "").trimmed
					lines.append(newLine)
				}
			}
			return lines.sorted().joined(separator: "\n")
        }
        return "Error"
    }
}
