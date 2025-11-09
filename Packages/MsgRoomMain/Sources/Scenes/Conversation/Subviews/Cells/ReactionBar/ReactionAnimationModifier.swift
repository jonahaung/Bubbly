//
//  ReactionAnimationModifier.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 5/11/25.
//

import SwiftUI

struct ReactionAnimationModifier: ViewModifier {
    let reactionType: ReactionType
    let isActive: Bool

    func body(content: Content) -> some View {
        Group {
            switch reactionType {
            case .heart:
                content
                    .scaleEffect(
                        isActive ? ReactionsView.Constants.scaleMultiplier : 1.0,
                        anchor: .bottom
                    )
            case .thumbsUp:
                content
                    .rotationEffect(
                        .degrees(
                            isActive ? -ReactionsView.Constants.rotationAngle : 0
                        ),
                        anchor: .bottomLeading
                    )
                    .scaleEffect(
                        isActive ? ReactionsView.Constants.scaleMultiplier : 1.0
                    )
            case .thumbsDown:
                content
                    .rotationEffect(
                        .degrees(
                            isActive ? -ReactionsView.Constants.rotationAngle : 0
                        ),
                        anchor: .leading
                    )
                    .scaleEffect(
                        isActive ? ReactionsView.Constants.scaleMultiplier : 1.0
                    )
            case .crying:
                content
                    .offset(
                        y: isActive ? ReactionsView.Constants.floatOffset : 0
                    )
                    .scaleEffect(
                        isActive ? ReactionsView.Constants.scaleMultiplier : 1.0
                    )
            case .sad:
                content
                    .offset(
                        y: isActive ? ReactionsView.Constants.floatOffset : 0
                    )
                    .rotationEffect(
                        .degrees(
                            isActive ? ReactionsView.Constants.rotationAngle : 0
                        )
                    )
                    .scaleEffect(
                        isActive ? ReactionsView.Constants.scaleMultiplier : 1.0
                    )
            }
        }
    }
}
