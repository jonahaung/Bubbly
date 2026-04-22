//
//  MsgCellReactionOverlay.swift
//  Conversation
//
//  Created by Aung Ko Min on 22/4/26.
//
import Database
import SwiftUI
struct MsgCellReactionOverlay: View {
    var body: some View { Reactions(reactions: reactions).fixedSize().equatable(by: reactions) }
    let reactions: [Reaction]
}
