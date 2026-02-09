//
//  PGroup.swift
//  Database
//
//  Created by Aung Ko Min on 23/10/25.
//

import Foundation
import SwiftData

@Model
public final class PGroup {
	@Attribute(.unique)
	public var uid: String
	public var name: String
	public var createdDate: String
	public var photoURL: String
	public var members: [String]
	public var createdBy: String
	public var theme: ConversationTheme
	public var seenMembers: [SeenMember]

	public init(uid: String,
	            name: String,
	            createdDate: String,
	            photoURL: String,
	            members: [String],
	            createdBy: String,
	            theme: ConversationTheme = ConversationTheme(),
	            seenMembers: [SeenMember])
	{
		self.uid = uid
		self.name = name
		self.createdDate = createdDate
		self.photoURL = photoURL
		self.members = members
		self.createdBy = createdBy
		self.theme = theme
		self.seenMembers = seenMembers
	}
}

extension PGroup: CollectionDocument, UIdentifiable {
	public func update(with conversation: Conversation) {
		if name != conversation.name {
			name = conversation.name
		}
		if photoURL != conversation.photoURL {
			photoURL = conversation.photoURL
		}
		if members.sorted() != conversation.members.sorted() {
			members = conversation.members
		}
		if theme != conversation.properties.theme {
			theme = conversation.properties.theme
		}
		if seenMembers != conversation.properties.seenMembers {
			seenMembers = conversation.properties.seenMembers
		}
	}

	public func update(from item: Group) {
		if name != item.name {
			name = item.name
		}
		if photoURL != item.photoURL {
			photoURL = item.photoURL ?? photoURL
		}
		if members.sorted() != item.members.sorted() {
			members = item.members
		}
		if theme != item.theme {
			theme = item.theme
		}
		if seenMembers != item.seenMembers {
			seenMembers = item.seenMembers
		}
	}
}

extension PGroup: SendableDocument {
	public typealias SendableType = Group

	public convenience init(from snapshot: SendableType) {
		self.init(
			uid: snapshot.uid,
			name: snapshot.name,
			createdDate: snapshot.createdDate.value,
			photoURL: snapshot.photoURL ?? "",
			members: snapshot.members,
			createdBy: snapshot.createdBy,
			seenMembers: snapshot.seenMembers
		)
	}

	public func toSendable() -> SendableType {
		SendableType(
			uid: uid,
			name: name,
			createdDate: .init(createdDate),
			photoURL: photoURL,
			members: members,
			createdBy: createdBy,
			theme: theme,
			seenMembers: seenMembers
		)
	}
}
