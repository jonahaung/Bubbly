//
//  FloatingDateView.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 27/4/25.
//
import SwiftUI

struct FloatingDateView: View {

	@Environment(ChatViewManager.self) private var manager

	@ViewBuilder
	var body: some View {
		if let string = manager.eventsManager.floatingDateString {
			Text(string)
				.font(.footnote.bold())
				.padding(.horizontal, 12)
				.padding(.vertical, 3)
				.background(manager.conversation.theme.background.color, in: .capsule)
				.transition(.move(edge: .top).combined(with: .scale(0.01, anchor: .top)))
		}
	}
}
