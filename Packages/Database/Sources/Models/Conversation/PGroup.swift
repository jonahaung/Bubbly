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
	public var lastMsgID: String?

	public init(
		uid: String,
		name: String,
		createdDate: String,
		photoURL: String,
		members: [String],
		createdBy: String,
		theme: ConversationTheme = ConversationTheme(),
		seenMembers: [SeenMember] = [],
		lastMsgID: String?
	) {
		self.uid = uid
		self.name = name
		self.createdDate = createdDate
		self.photoURL = photoURL
		self.members = members
		self.createdBy = createdBy
		self.theme = theme
		self.seenMembers = seenMembers
		self.lastMsgID = lastMsgID
	}
}
extension PGroup: CollectionDocument, UIdentifiable {
	public func update(with group: Database.Group) {
		if name != group.name {
			name = group.name
		}
		if photoURL != group.photoURL {
			photoURL = group.photoURL ?? photoURL
		}
		if members.sorted() != group.members.sorted() {
			members = group.members
		}
		if theme != group.theme {
			theme = group.theme
		}
		if lastMsgID != group.lastMsgID {
			lastMsgID = lastMsgID
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
			createdBy: snapshot.createdBy, lastMsgID: snapshot.lastMsgID)
	}

	public func toSendable() -> SendableType {
		SendableType(
			uid: uid,
			name: name,
			createdDate: .init(createdDate),
			photoURL: photoURL,
			members: members,
			createdBy: createdBy,
			theme: theme, lastMsgID: lastMsgID)
	}
}
