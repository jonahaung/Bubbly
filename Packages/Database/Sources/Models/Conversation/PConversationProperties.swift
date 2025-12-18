//
//  PConversation.swift
//  Database
//
//  Created by Aung Ko Min on 10/12/25.
//

import SwiftData

@Model
public final class PConversationProperties {

	@Attribute(.unique)
	public var uid: String
	public var theme: ConversationTheme
	public var seenMembers: [SeenMember]

	public init(
		uid: String,
		theme: ConversationTheme,
		seenMembers: [SeenMember]
	) {
		self.uid = uid
		self.theme = theme
		self.seenMembers = seenMembers
	}
}

extension PConversationProperties: CollectionDocument, SendableDocument {
	public func update(from item: ConversationProperties) {
		theme = item.theme
		seenMembers = item.seenMembers
	}
	public convenience init(from sendable: ConversationProperties) {
		self.init(
			uid: sendable.uid,
			theme: sendable.theme,
			seenMembers: sendable.seenMembers,
		)
	}

	public func toSendable() -> ConversationProperties {
		.init(
			uid: uid,
			theme: theme,
			seenMembers: seenMembers
		)
	}
}
