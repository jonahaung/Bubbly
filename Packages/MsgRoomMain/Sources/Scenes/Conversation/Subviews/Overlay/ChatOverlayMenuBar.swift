//
//  ChatOverlayMenuBar.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 3/11/25.
//

import SwiftUI

struct ChatOverlayMenuBar: View {
	@State private var heartReactionCount = 0
	@State private var upReactionCount = 0
	@State private var downReactionCount = 0
	@State private var lolReactionCount = 0
	@State private var wutReactionCount = 0

	var body: some View {
		HStack {
			Button {
				heartReactionCount += 1
			} label: {
				Image(.loveReaction)
			}
			.reactionAnimation(trigger: $heartReactionCount)

			Button {
				upReactionCount += 1
			} label: {
				Image(.thumbsupReaction)
			}
			.reactionAnimation(trigger: $upReactionCount)

			Button {
				downReactionCount += 1
			} label: {
				Image(.thumbsdownReaction)
			}
			.reactionAnimation(trigger: $downReactionCount)

			Button {
				lolReactionCount += 1
			} label: {
				Image(.lolReaction)
			}
			.reactionAnimation(trigger: $lolReactionCount)

			Button {
				wutReactionCount += 1
			} label: {
				Image(.wutReaction)
			}
			.reactionAnimation(trigger: $wutReactionCount)
		}
		.tint(Color.darkGray)
	}
}
