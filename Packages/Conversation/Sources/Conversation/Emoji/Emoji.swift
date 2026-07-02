//  Emoji.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Foundation

public struct Emoji: Hashable, Identifiable {
    public var id: String {
        value
    }

    public let value: String
    public let category: String
    public let aliases: [String]
    public let tags: [String]
}

extension Emoji: Decodable {
    enum CodingKeys: String, CodingKey {
        case value = "emoji"
        case category
        case aliases
        case tags
    }
}
