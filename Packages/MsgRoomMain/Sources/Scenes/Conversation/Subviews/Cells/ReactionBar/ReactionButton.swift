//
//  ReactionButton.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 5/11/25.
//
import SwiftUI

struct ReactionButton: View {
    @Binding var reactionState: ReactionsView.ReactionState
    let isVisible: Bool

    @State private var currentAnimationState = false

    private var reactionType: ReactionType {
        reactionState.id
    }

    var body: some View {
        Button {
            handleReactionTap()
        } label: {
            Text(reactionType.icon)
                .font(.headline)
                .padding(.vertical, 8)
                .padding(.horizontal, 2)
                .scaleEffect(isVisible ? 1.0 : 0.1)
                .opacity(isVisible ? 1.0 : 0.0)
        }
        .buttonStyle(ReactionButtonStyle())
        .sensoryFeedback(.selection, trigger: reactionState)
        .accessibilityLabel("\(reactionType.displayName) reaction")
        .accessibilityValue("\(reactionState.count) taps")
        .phaseAnimator([false, true], trigger: reactionState.count) { content, phase in
            content
                .modifier(ReactionAnimationModifier(
                    reactionType: reactionType,
                    isActive: phase
                ))
        } animation: { _ in
            .bouncy(duration: reactionType.animationDuration, extraBounce: 0.4)
        }
    }

    private func handleReactionTap() {
        reactionState.count += 1
        currentAnimationState.toggle()
    }
}

private struct ReactionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
