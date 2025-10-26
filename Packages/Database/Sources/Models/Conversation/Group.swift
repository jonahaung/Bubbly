//
//  Group.swift
//  Database
//
//  Created by Aung Ko Min on 20/8/25.
//

import Foundation

public struct Group: Codable, Sendable, Hashable, UIdentifiable {

	public var uid: String
	public var name: String
	public var createdDate: ServerTime
	public var photoURL: String?
	public var members: [String]
	public var createdBy: String
	public var theme: ConversationTheme = .init()
	public var seenMembers: [SeenMember]? = nil
	public var lastMsgID: String? = nil

	public init(
		uid: String,
		name: String,
		createdDate: ServerTime,
		photoURL: String?,
		members: [String],
		createdBy: String,
		theme: ConversationTheme = .init(),
		seenMembers: [SeenMember] = [],
		lastMsgID: String? = nil
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
