//
//  ConversationIDGenerator.swift
//  Database
//
//  Created by Aung Ko Min on 11/12/25.
//

import Foundation

public enum ConversationIDGenerator {
	public static func generate(_ lhs: String, _ rhs: String) -> String {
		lhs > rhs ? rhs + "|" + lhs : lhs + "|" + rhs
	}
}
