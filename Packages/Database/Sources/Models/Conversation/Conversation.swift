//
//  AnyConversation.swift
//  Database
//
//  Created by Aung Ko Min on 24/10/25.
//

import Core
import Foundation
import XUI

public struct Conversation: Codable, Sendable, Hashable, Equatable, UIdentifiable {

	public let kind: ConversationKind
	public let uid: String
	public let name: String
	public let photoURL: String
	public let members: [String]
	public var properties: ConversationProperties

	public init(kind: ConversationKind, uid: String, properties: ConversationProperties) {
		self.kind = kind
		self.uid = uid
		self.properties = properties

		switch kind {
		case .contact(let contact):
			self.name = contact.name
			self.photoURL = contact.photoURL
			self.members = [contact.uid]
		case .group(let group):
			self.name = group.name
			self.photoURL = group.photoURL ?? ""
			self.members = group.members
		case .system(let ai):
			self.name = ai.name
			self.photoURL = ai.photoURL
			self.members = []
		}
	}
}
extension Conversation: EmptyRepresentable {
	public static let empty: Conversation = .init(.contact(.empty), properties: .empty)
}
extension Conversation {
	public var theme: ConversationTheme {
		get { properties.theme }
		set { properties.theme = newValue }
	}
	public init(_ kind: ConversationKind, properties: ConversationProperties) {
		guard let currentUserID = GroupStorage.shared.string(for: .auth(.currentUserID)) else {
			preconditionFailure("Missing currentUserID in GroupAppStorage")
		}
		switch kind {
		case .contact(let contact):
			let uid = ConversationIDGenerator.generate(currentUserID, contact.uid)
			self.init(
				kind: kind,
				uid: uid,
				properties: properties
			)
		case .group(let group):
			let uid = group.uid
			self.init(
				kind: kind,
				uid: uid,
				properties: properties
			)
		case .system(let contact):
			let uid = ConversationIDGenerator.generate(currentUserID, contact.uid)
			self.init(
				kind: kind,
				uid: uid,
				properties: properties
			)
		}
	}

	@concurrent
	public func reload(refetch: Bool = false) async throws -> Self {
		try await ConversationRepo
			.getOrCreate(for: uid, refetch: refetch)
	}

	public func saveChanges() async throws {
		try await Store.shared.conversationPropertiesStore.updateAndSave(uid: uid) { value in
			value.theme = properties.theme
			value.seenMembers = properties.seenMembers
		}
	}
}

enum ConversationError: Error {
	case invalidType
}
