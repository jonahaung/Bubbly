//  Reaction.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import Core
import Foundation

public struct Reaction: Codable, Sendable, Hashable, Equatable, Identifiable {
    public var id: String {
        rawValue + senderID
    }

    public let rawValue: String
    public let senderID: String
    public let date: Date

    public init(rawValue: String, senderID: String, date: Date) {
        self.rawValue = rawValue
        self.senderID = senderID
        self.date = date
    }
}
