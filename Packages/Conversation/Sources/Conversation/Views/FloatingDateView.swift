//
//  FloatingDateView.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 27/4/25.
//
import SwiftUI

struct FloatingDateView: View, Animatable {
	@Environment(ChatViewManager.self) private var manager

	var animatableData: String? {
		get { manager.presentation.floatingDateString }
		set { manager.presentation.updateFloatingDate(newValue) }
	}

	var body: some View {
		if let string = manager.presentation.floatingDateString {
			Text(string)
				.font(.footnote.bold())
				.lineHeight(.normal)
				.lineSpacing(0)
				.padding(.horizontal, 12)
				.padding(.vertical, 4)
				.background(manager.conversation.properties.theme.background.color, in: .capsule)
		}
	}
}
