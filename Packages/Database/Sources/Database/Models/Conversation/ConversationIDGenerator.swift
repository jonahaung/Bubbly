//  ConversationIDGenerator.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import Foundation

public enum ConversationIDGenerator {
    public static func generate(_ lhs: String, _ rhs: String) -> String {
        lhs > rhs ? rhs + "|" + lhs : lhs + "|" + rhs
    }
}
