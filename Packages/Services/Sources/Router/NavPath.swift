//
//  NavPath.swift
//  Services
//
//  Created by Aung Ko Min on 18/8/25.
//

import Foundation
import Database

public enum NavPath: Hashable, Sendable, Identifiable {
	case conversationDetails(any ConversationRepresentable)
	case conversation(ConversationInitializer.PrefetchedData)
	case contactDetails(Contact)
	case currentUserDetails
	case cachedView(String)

	public var id: String {
		self.hashValue.description
	}

	// ✅ You don't need to manually implement == — Swift synthesizes it from `hash(into:)`
	public func hash(into hasher: inout Hasher) {
		switch self {
		case .conversationDetails(let snapshot):
			hasher.combine(0)
			hasher.combine(snapshot.uid)

		case .conversation(let data):
			hasher.combine(1)
			hasher.combine(data.conversation.uid)

		case .contactDetails(let snapshot):
			hasher.combine(2)
			hasher.combine(snapshot.uid)

		case .currentUserDetails:
			hasher.combine(3)

		case .cachedView(let id):
			hasher.combine(4)
			hasher.combine(id)
		}
	}
	public static func == (lhs: NavPath, rhs: NavPath) -> Bool {
		lhs.id == rhs.id
	}
}
