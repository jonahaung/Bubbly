//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public extension Encodable {
    func asDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        let object = try JSONSerialization.jsonObject(with: data, options: [])
        guard let dict = object as? [String: Any] else {
            throw NSError(
                domain: "Encodable+Dictionary",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Top-level JSON is not a dictionary."]
            )
        }
        return dict
    }

    var dictionary: [String: Any] {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(self) else { return [:] }
        return (try? JSONSerialization.jsonObject(with: data, options: .allowFragments))
            .flatMap { $0 as? [String: Any] } ?? [:]
    }

    var jsonData: Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try? encoder.encode(self)
    }

    var preetyPrinted: String {
        if let jsonData {
            return String(data: jsonData, encoding: .utf8) ?? "Error"
        }
        return "Error"
    }
}
