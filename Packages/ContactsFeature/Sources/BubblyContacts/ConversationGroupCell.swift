//
//  ConversationGroupCell.swift
//  Contacts
//
//  Created by Aung Ko Min on 6/4/26.
//


import Database
import Services
import SwiftUI
import XUI

struct ConversationGroupCell: View {
    let group: Database.Group

    var body: some View {
        AsyncButton {
            try await ConversationInitializer.start(conversation: Conversation(
                .group(group)
            ))
        } label: {
            HStack(spacing: 20) {
                ProfilePhoto(
                    group
                )
                .padding(.vertical, 2)
                Text(group.name)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("\(group.members.count) members")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.borderless)
        .foregroundStyle(Color.primary)
    }
}
