//
//  AnyConversation.swift
//  Database
//
//  Created by Aung Ko Min on 24/10/25.
//

import Foundation
import Core

public struct AnyConversation: ConversationRepresentable {
	static func createConversationID(for one: String, two: String) -> String {
		one > two ? two+"|"+one : one+"|"+two
	}
	public let kind: ConversationKind
	public let uid: String
	public var name: String
	public var photoURL: String
	public var members: [String]
	public var theme: ConversationTheme
	public var lastMsgID: String?
	public var seenMembers: [SeenMember]


	public init(_ kind: ConversationKind) {

		switch kind {
		case .contact(let contact):
			uid = contact.uid
			name = contact.name
			photoURL = contact.photoURL
			theme = contact.theme ?? .default
			members = [contact.uid]
			lastMsgID = contact.lastMsgID
			if let lastMsgID = contact.lastMsgID {
				seenMembers = [.init(uid: contact.uid, msgId: lastMsgID, date: ServerTime.now.value)]
			} else {
				seenMembers = []
			}
		case .group(let group):
			uid = group.uid
			name = group.name
			photoURL = group.photoURL ?? .init()
			theme = group.theme
			members = group.members
			lastMsgID = group.lastMsgID
			seenMembers = group.seenMembers ?? []
		case .system(let ai):
			uid = ai.uid
			name = ai.name
			photoURL = ai.photoURL
			theme = ai.theme
			members = []
			lastMsgID = ai.lastMsgID
			if let lastMsgID = ai.lastMsgID {
				seenMembers = [.init(uid: ai.uid, msgId: lastMsgID, date: ServerTime.now.value)]
			} else {
				seenMembers = []
			}
		}
		self.kind = kind
	}

	public func updateChanges() async throws {
		switch kind {
		case .contact(let contact):
			try await Store.shared.contactStore.updateAndSave(uid: contact.uid) { model in
				model.theme = theme
				model.lastMsgID = lastMsgID
			}
		case .group(let group):
			try await Store.shared.groupStore.updateAndSave(uid: group.uid) { model in
				model.theme = theme
				model.lastMsgID = lastMsgID
			}
		case .system(_):
			break
		}
	}

	public mutating func reload() async throws {
		switch kind {
		case .contact(let contact):
			guard let newContact = try await Store.shared.contactStore.fetch(uid: contact.uid) else { return }
			self = AnyConversation(.contact(newContact))
		case .group(let group):
			guard let group = try await Store.shared.groupStore.fetch(uid: group.uid) else { return }
			self = AnyConversation(.group(group))
		case .system( _):
			break
		}
	}
}
