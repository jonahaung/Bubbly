//
//  StringMergable.swift
//  XUI
//
//  Created by Aung Ko Min on 10/12/25.
//

import Foundation

public protocol StringMergable {}
public extension StringMergable {
    func mergedString(_ current: String, from incoming: String) -> String {
		let trimmed = incoming.trimmed
		return trimmed.isWhitespace ? current : trimmed
    }
}
