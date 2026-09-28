//  ConversationGroupCell.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import XUI
import SwiftUI
import Database
import Services

struct ConversationGroupCell: View {
    let group: Database.Group

    var body: some View {
        AsyncButton {
            try await ConversationInitializer.start(conID: group.uid, refetch: false)
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
