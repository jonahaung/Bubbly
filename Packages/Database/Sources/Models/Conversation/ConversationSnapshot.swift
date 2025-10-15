//
//  ConversationSnapshot.swift
//  Models
//
//  Created by Aung Ko Min on 12/7/25.
//
import Foundation
import SwiftData

public struct ConversationSnapshot: Codable, Sendable, Hashable, UIdentifiable {

	public var uid: String
	public var name: String
	public var type: ConversationType
	public var createdDate: Date
	public var photoURL: String?
	public var members: Set<String>
	public var createdBy: String?
	public var theme: ConversationTheme
	public var seenMembers: [SeenMember]

	public init(
		uid: String,
		name: String,
		type: ConversationType,
		createdDate: Date,
		photoURL: String?,
		members: Set<String>,
		createdBy: String? = nil,
		theme: ConversationTheme = .init(),
		seenMembers: [SeenMember] = []
	) {
		self.uid = uid
		self.name = name
		self.type = type
		self.createdDate = createdDate
		self.photoURL = photoURL
		self.members = members
		self.createdBy = createdBy
		self.theme = theme
		self.seenMembers = seenMembers
	}

	public init(model: PConversation) {
		self.init(
			uid: model.uid,
			name: model.name,
			type: .init(rawValue: model.type) ?? .single,
			createdDate: ServerTime(model.createdDate).date,
			photoURL: model.photoURL,
			members: model.members,
			createdBy: model.createdBy,
			theme: model.theme ?? .init(),
			seenMembers: model.seenMembers
		)
	}

	public init(group: Group) {
		self.init(
			uid: group.uid,
			name: group.name,
			type: .group,
			createdDate: group.createdDate.date,
			photoURL: group.photoURL,
			members: Set(group.members),
			createdBy: group.createdBy,
			theme: group.theme,
			seenMembers: []
		)
	}
}

extension PConversation: SendableDocument {

	public typealias SendableType = ConversationSnapshot

	public convenience init(from snapshot: ConversationSnapshot) {
		self.init(
			uid: snapshot.uid,
			name: snapshot.name,
			type: snapshot.type,
			createdDate: .init(snapshot.createdDate),
			photoURL: snapshot.photoURL,
			members: snapshot.members,
			createdBy: snapshot.createdBy,
			theme: snapshot.theme,
			seenMembers: snapshot.seenMembers
		)
	}

	public func toSendable() -> ConversationSnapshot {
		SendableType(
			uid: uid,
			name: name,
			type: .init(rawValue: type) ?? .single,
			createdDate: ServerTime(createdDate).date,
			photoURL: photoURL,
			members: members,
			createdBy: createdBy,
			theme: theme ?? ConversationTheme(),
			seenMembers: seenMembers
		)
	}
}
public extension ConversationSnapshot {

	mutating func update(with group: Group) {
		self.name = group.name
		self.photoURL = group.photoURL
		self.members = Set(group.members)
		self.theme = group.theme
	}

	mutating func update(with contact: ContactSnapshot) {
		self.name = contact.name
		self.photoURL = contact.photoURL
		self.members = [contact.uid]
	}
}
