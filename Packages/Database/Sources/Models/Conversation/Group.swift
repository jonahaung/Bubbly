//
//  Group.swift
//  Database
//
//  Created by Aung Ko Min on 20/8/25.
//

import Foundation

public struct Group: Codable, Sendable, UIdentifiable {

	public var uid: String
	public var name: String
	public var createdDate: ServerTime
	public var photoURL: String?
	public var members: [String]
	public var createdBy: String
	public var theme: ConversationTheme = .init()

	public init(
		uid: String,
		name: String,
		createdDate: ServerTime,
		photoURL: String?,
		members: [String],
		createdBy: String,
		theme: ConversationTheme = .init()
	) {
		self.uid = uid
		self.name = name
		self.createdDate = createdDate
		self.photoURL = photoURL
		self.members = members
		self.createdBy = createdBy
		self.theme = theme
	}

	public init(snapshot: ConversationSnapshot) {
		self.init(
			uid: snapshot.uid,
			name: snapshot.name,
			createdDate: .init(
				snapshot.createdDate
			),
			photoURL: snapshot.photoURL,
			members: Array(snapshot.members),
			createdBy: snapshot.createdBy ?? "",
			theme: snapshot.theme
		)
	}
}
