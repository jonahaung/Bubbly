//
//  ReactionType.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 5/11/25.
//

import SwiftUI

public enum ReactionType: Sendable, Hashable, CaseIterable, Identifiable {
	public var id: String { icon }
	case heart, thumbsUp, thumbsDown, crying, sad

	var icon: String {
		switch self {
		case .heart:
			return "❤️"
		case .thumbsUp:
			return "👍"
		case .thumbsDown:
			return "👎"
		case .crying:
			return "😂"
		case .sad:
			return "😓"
		}
	}
	var displayName: String {
		switch self {
		case .heart: return "Heart"
		case .thumbsUp: return "Thumbs Up"
		case .thumbsDown: return "Thumbs Down"
		case .crying: return "Crying"
		case .sad: return "Sad"
		}
	}

	var animationDuration: Double {
		switch self {
		case .heart, .thumbsUp:
			return ReactionsView.Constants.animationDuration
		case .thumbsDown, .crying, .sad:
			return ReactionsView.Constants.animationDuration / 2
		}
	}
}
