//
//  NavPath.swift
//  Services
//
//  Created by Aung Ko Min on 18/8/25.
//

import Database
import Foundation
import XUI

public enum NavPath: Hashable, Sendable, Identifiable, CaseNameReflectable {
	case conversationDetails(_ conversation: any ConversationRepresentable)
	case conversation(_ prefatchData: ConversationInitializer.PrefetchedData)
	case contactDetails(_ contact: Contact)
	case currentUserDetails

	public var id: String {
		hashValue.description
	}

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
		}
	}

	public static func == (lhs: NavPath, rhs: NavPath) -> Bool {
		lhs.id == rhs.id
	}
}
