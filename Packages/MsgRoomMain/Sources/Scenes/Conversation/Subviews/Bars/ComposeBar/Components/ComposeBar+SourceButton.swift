//
//  ComposeBar+SourceButton.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 3/1/26.
//

import SwiftUI
import XUI

extension ComposeBar {
	struct ComposeBarSourceButton: View {
		let source: ChatComposer.Source
		@Environment(ConversationViewModel.self) private var viewModel
		@Environment(\.sharedNamespace) private var namespace
		var body: some View {
			Button(action: action) {
				Image(systemName: source.systemImageName)
					.resizable()
					.frame(square: 20)
					.foregroundStyle(source.foreGroundStyle)
			}
			.frame(square: 38)
			.background(.windowBackground, in: .circle)
			.equatable(by: source)
		}

		private func action() {
			viewModel.send(.updateComposerSource(source))
		}
	}
}
