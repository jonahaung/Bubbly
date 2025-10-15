//
//  ConversationGroupCell.swift
//  Bubbly
//
//  Created by Aung Ko Min on 20/8/25.
//

import SwiftUI
import Database
import Services
import XUI

struct ConversationGroupCell: View {
	
	let group: ConversationSnapshot
	
	var body: some View {
		Button {
			ConversationInitializer.start(conversation: group)
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
