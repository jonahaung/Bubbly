//
//  PConversation.swift
//  MsgRoom
//
//  Created by Aung Ko Min on 14/7/24.
//
import Foundation
import SwiftData

@Model
public final class PConversation {
	
	public var uid = String()
	public var name = String()
	public var type = Int(0)
	public var createdDate = String()
	public var photoURL: String?
	public var members = Set<String>()
	public var createdBy: String?
	public var seenMembers = [SeenMember]()
	public var theme: ConversationTheme? = ConversationTheme()

	public init(
		uid: String,
		name: String,
		type: ConversationType,
		createdDate: ServerTime,
		photoURL: String?,
		members: Set<String>,
		createdBy: String?,
		theme: ConversationTheme,
		seenMembers: [SeenMember]
	) {
		self.uid = uid
		self.name = name
		self.type = type.rawValue
		self.createdDate = createdDate.value
		self.photoURL = photoURL
		self.members = members
		self.createdBy = createdBy
		self.theme = theme
		self.seenMembers = seenMembers
	}
}
extension PConversation: CollectionDocument, UIdentifiable {
	public func update(with snapshot: ConversationSnapshot) {
		if name != snapshot.name {
			name = snapshot.name
		}
		if photoURL != snapshot.photoURL {
			photoURL = snapshot.photoURL
		}

		if !snapshot.members.isEmpty && members != snapshot.members {
			members = snapshot.members
		}
		if theme != snapshot.theme {
			theme = snapshot.theme
		}
	}
	public func update(with group: Group) {
		if name != group.name {
			name = group.name
		}
		if photoURL != group.photoURL {
			photoURL = group.photoURL
		}
		if members.sorted() != group.members.sorted() {
			members = Set(group.members)
		}
		if theme != group.theme {
			theme = group.theme
		}
	}
	public func update(with contact: ContactSnapshot) {
		if name != contact.name {
			name = contact.name
		}
		if photoURL != contact.photoURL {
			photoURL = contact.photoURL
		}
	}
}
