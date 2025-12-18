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
			"❤️"
		case .thumbsUp:
			"👍"
		case .thumbsDown:
			"👎"
		case .crying:
			"😂"
		case .sad:
			"😓"
		}
	}

	var imageResource: ImageResource {
		switch self {
		case .heart:
			return .loveReaction
		case .thumbsUp:
			return .thumbsupReaction
		case .thumbsDown:
			return .thumbsdownReaction
		case .crying:
			return .lolReaction
		case .sad:
			return .wutReaction

		}
	}

	var displayName: String {
		switch self {
		case .heart: "Heart"
		case .thumbsUp: "Thumbs Up"
		case .thumbsDown: "Thumbs Down"
		case .crying: "Crying"
		case .sad: "Sad"
		}
	}

	var animationDuration: Double {
		switch self {
		case .heart, .thumbsUp:
			ReactionsView.Constants.animationDuration
		case .thumbsDown, .crying, .sad:
			ReactionsView.Constants.animationDuration / 2
		}
	}
}
