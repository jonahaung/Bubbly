//
//  Reaction.swift
//  MsgRoom
//
//  Created by Aung Ko Min on 6/4/24.
//

import Core
import Foundation
import XUI

public struct Reaction: Codable, Sendable, Hashable, Equatable, Identifiable {
	public var id: String {
		rawValue + senderID
	}

	public let rawValue: String
	public let senderID: String
	public let date: ServerTime

	public init(rawValue: String, senderID: String, date: ServerTime) {
		self.rawValue = rawValue
		self.senderID = senderID
		self.date = date
	}
}
