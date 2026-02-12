//
//  ComposeBar+SendButton.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 3/1/26.
//

import Database
import SwiftUI
import XUI

extension ComposeBar {
	struct ComposeBarSendButton: View {
		@Environment(ChatComposer.self) private var composer: ChatComposer
		@Environment(ConversationViewModel.self) private var viewModel

		var body: some View {
			AsyncButton(
				options: [.disallowParallelOperations, .showAlertOnError]
			) {
				viewModel.send(.sendMessage(composer.inputText.text))
			} label: {
				Image(systemName: imageName)
					.resizable()
					.scaledToFit()
					.frame(square: 24)
			}
			.frame(width: 44, height: 44, alignment: .center)
			.background(.windowBackground, in: .circle)
			.overlay {
				if composer.isLoading {
					LoadingIndicator(43)
						.opacity(0.5)
				}
			}
		}

		var imageName: String {
			composer.hasContent ? "paperplane.fill" : "character.cursor.ibeam"
		}
	}
}
