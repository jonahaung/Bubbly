//  MsgCellReactionOverlay.swift
//
//  Copyright © 2026 Aung Ko Min.
//

//
//  MsgCellReactionOverlay.swift
//  Conversation
//
//  Created by Aung Ko Min on 22/4/26.
//
import SwiftUI
import Database

struct MsgCellReactionOverlay: View, @MainActor Equatable {

    let reactions: [Reaction]
    var body: some View {
        ReactionStackLayout {
            ForEach(
                Array(reactions.reversed().enumerated()),
                id: \.element
            ) { index, reaction in
                Text(reaction.rawValue)
                    .font(.footnote)
                    .offset(x: index.cgFloat * -12)
                    .transition(.movingParts.pop(.yellow))
            }
        }
        .offset(y: -10)
        .padding(.horizontal, 8)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.reactions == rhs.reactions
    }
}
