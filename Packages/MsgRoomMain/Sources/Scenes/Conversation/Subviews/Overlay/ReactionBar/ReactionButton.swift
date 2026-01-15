//
//  ReactionButton.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 5/11/25.
//
import SwiftUI
import Database
import Core

struct ReactionButton: View {

	@Binding var reactionState: ReactionsBar.ReactionState
	let onReact: (String) -> Void

	var body: some View {
		Button {
			handleReactionTap()
		} label: {
			Text(reactionState.reaction)
				.phaseAnimator([false, true], trigger: reactionState.count) {
 content,
 phase in
					content
						.modifier(
							ReactionAnimationModifier(
								reaction: reactionState.reaction,
								isActive: phase
							)
						)
				} animation: { _ in
						.bouncy(
							duration: reactionState.animationDuration,
							extraBounce: ReactionsBar.Constants
								.extraBounce)
				}
		}
		.buttonStyle(.plain)
		.sensoryFeedback(.selection, trigger: reactionState)
	}
	
	private func handleReactionTap() {
		reactionState.count += 1
		DispatchQueue.delay(reactionState.animationDuration * 3) {
			onReact(reactionState.reaction)
		}
	}
}

private struct ReactionButtonStyle: ButtonStyle {
	func makeBody(configuration: Configuration) -> some View {
		configuration.label
			.scaleEffect(configuration.isPressed ? 0.9 : 1.0)
			.animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
	}
}
