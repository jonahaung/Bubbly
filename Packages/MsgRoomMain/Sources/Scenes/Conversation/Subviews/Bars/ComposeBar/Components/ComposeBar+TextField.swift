//
//  ComposeBar+TextField.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 17/1/26.
//

import Services
import SwiftUI
import XUI

extension ComposeBar {
	struct ComposeBarInputTextField: View {
		@Bindable var composer: ChatComposer
		@Environment(\.sharedFocusState) private var focusState
		@Environment(\.conversationTheme) private var theme
		@Environment(\.sharedNamespace) private var namespace
		var body: some View {
			ZStack(alignment: .trailing) {
				textField()
			}
			.background(.background, in: .containerRelative)
			.containerShape(RoundedRectangle(cornerRadius: theme.bubbleCornorRadius))
		}

		private func textField() -> some View {
			TextField(
				"\(composer.source.rawValue)",
				text: $composer.inputText
					.text, selection: $composer.inputText.selection, axis: .vertical)
			.lineLimit(0...10)
			.font(.body)
			.tint(.link)
			.padding(.init(top: 8, leading: 16, bottom: 8, trailing: 8))
			.focused(
				focusState.unsafelyUnwrapped.binding,
				equals: composer.source.rawValue
			)
		}

		
	}
}
