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
		case let .contact(contact):
			name = contact.name
			photoURL = contact.photoURL
			members = [contact.uid]
		case let .group(group):
			name = group.name
			photoURL = group.photoURL ?? ""
			members = group.members
		}
	}
}

extension Conversation: EmptyRepresentable {
	public static let empty: Conversation = .init(.contact(.empty), properties: .empty)
}

public extension Conversation {
	var theme: ConversationTheme {
		get { properties.theme }
		set { properties.theme = newValue }
	}

	init(_ kind: ConversationKind, properties: ConversationProperties) {
		guard let currentUserID = GroupStorage.shared.string(for: .auth(.currentUserID)) else {
			preconditionFailure("Missing currentUserID in GroupAppStorage")
		}
		switch kind {
		case let .contact(contact):
			let uid = ConversationIDGenerator.generate(currentUserID, contact.uid)
			self.init(
				kind: kind,
				uid: uid,
				properties: properties
			)
		case let .group(group):
			let uid = group.uid
			self.init(
				kind: kind,
				uid: uid,
				properties: properties
			)
		}
	}

	@concurrent
	func reload(refetch: Bool = false) async throws -> Self {
		try await ConversationRepo
			.getOrCreate(for: uid, refetch: refetch)
	}

	@concurrent
	func saveChanges() async throws {
		try await Store.shared.conversationPropertiesStore?.updateAndSave(uid: uid) { value in
			value.update(from: properties)
		}
	}
}

enum ConversationError: Error {
	case invalidType
}
