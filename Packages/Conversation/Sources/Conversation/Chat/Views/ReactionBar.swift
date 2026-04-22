//  ReactionBar.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Core
import SwiftUI

struct ReactionBar: View {

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Button {
                heartReactionCount += 1
            } label: {
                Image(systemName: "heart.fill")
            }
            .reactionAnimation(trigger: $heartReactionCount)

            Button {
                upReactionCount += 1
            } label: {
                Image(systemName: "hand.thumbsup.fill")
            }
            .reactionAnimation(trigger: $upReactionCount)

            Button {
                downReactionCount += 1
            } label: {
                Image(systemName: "hand.thumbsdown.fill")
            }
            .reactionAnimation(trigger: $downReactionCount)

            Button {
                lolReactionCount += 1
            } label: {
                Image(systemName: "face.smiling")
            }
            .reactionAnimation(trigger: $lolReactionCount)

            Button {
                wutReactionCount += 1
            } label: {
                Image(systemName: "questionmark.circle.fill")
            }
            .reactionAnimation(trigger: $wutReactionCount)
        }
        .tint(Color.darkGray)
    }

    @State private var heartReactionCount = 0
    @State private var upReactionCount = 0
    @State private var downReactionCount = 0
    @State private var lolReactionCount = 0
    @State private var wutReactionCount = 0
}
