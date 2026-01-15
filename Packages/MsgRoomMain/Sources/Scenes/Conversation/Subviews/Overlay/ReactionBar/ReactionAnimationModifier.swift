//
//  ReactionAnimationModifier.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 5/11/25.
//

import SwiftUI
import Database

struct ReactionAnimationModifier: ViewModifier {

	let reaction: String
	let isActive: Bool

	func body(content: Content) -> some View {
		switch reaction {
		case "❤️":
			content
				.offset(y: isActive ? ReactionsBar.Constants.floatOffset/2 : 0)
				.scaleEffect(
					isActive ? ReactionsBar.Constants.scaleMultiplier : 1.0,
					anchor: .bottom
				)
		case "👍":
			content
				.rotationEffect(
					.degrees(isActive ? -ReactionsBar.Constants.rotationAngle : 0),
					anchor: .bottomLeading
				)
				.scaleEffect(isActive ? ReactionsBar.Constants.scaleMultiplier : 1.0)

		case "👎":
			content
				.rotationEffect(
					.degrees(isActive ? -ReactionsBar.Constants.rotationAngle : 0),
					anchor: .leading
				)
				.scaleEffect(isActive ? ReactionsBar.Constants.scaleMultiplier : 1.0)

		case "😂":
			content
				.offset(y: isActive ? ReactionsBar.Constants.floatOffset : 0)
				.scaleEffect(isActive ? ReactionsBar.Constants.scaleMultiplier : 1.0)

		case "😓":
			content
				.offset(y: isActive ? ReactionsBar.Constants.floatOffset : 0)
				.rotationEffect(
					.degrees(isActive ? ReactionsBar.Constants.rotationAngle : 0)
				)
				.scaleEffect(isActive ? ReactionsBar.Constants.scaleMultiplier : 1.0)
		default:
			content
				.scaleEffect(
					isActive ? ReactionsBar.Constants.scaleMultiplier : 1.0,
					anchor: .bottom
				)
		}
	}
}
