//
//  NavPath.swift
//  Services
//
//  Created by Aung Ko Min on 18/8/25.
//

import Foundation
import Database

public enum NavPath: Hashable, Sendable {

	case conversationDetails(ConversationSnapshot)
	case conversation(ConversationInitializer.PrefetchedData)
	case contactDetails(ContactSnapshot)
	case currentUserDetails

	public var id: String {
		switch self {
		case .conversationDetails(let snapshot):
			return "conversationDetails" + snapshot.uid
		case .conversation(let data):
			return "conversation" + data.conversation.uid
		case .contactDetails(let snapshot):
			return "contactDetails" + snapshot.uid
		case .currentUserDetails:
			return "currentUserDetails"
		}
	}

	public static func == (lhs: NavPath, rhs: NavPath) -> Bool {
		lhs.id == rhs.id
	}
	public func hash(into hasher: inout Hasher) {
		switch self {
		case .conversationDetails(let snapshot):
			"conversationDetails".hash(into: &hasher)
			snapshot.hash(into: &hasher)
		case .conversation(let data):
			data.conversation.hash(into: &hasher)
		case .contactDetails(let snapshot):
			snapshot.hash(into: &hasher)
		case .currentUserDetails:
			"currentUserDetails".hash(into: &hasher)
		}
	}
}
