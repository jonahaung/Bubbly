//
//  ConversationRepresentable.swift
//  Database
//
//  Created by Aung Ko Min on 23/10/25.
//

import Foundation
import XUI
import Core

public protocol ConversationRepresentable: Codable, Sendable, Hashable, Equatable, UIdentifiable {
	var uid: String { get }
	var kind: ConversationKind { get }
	var name: String { get }
	var photoURL: String { get }
	var members: [String] { get }
	var theme: ConversationTheme { get }
	var seenMembers: [SeenMember] { get set }
	var lastMsgID: String? { get set }
	func updateChanges() async throws
	mutating func reload() async throws
}
