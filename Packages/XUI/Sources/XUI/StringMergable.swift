//  StringMergable.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import Foundation

public protocol StringMergable {}
public extension StringMergable {
    func mergedString(_ current: String, from incoming: String) -> String {
        let trimmed = incoming.trimmed
        return trimmed.isWhitespace ? current : trimmed
    }
}
