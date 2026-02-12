//
//  ChatAccessoryBar.swift
//  Msgr
//
//  Created by Aung Ko Min on 21/10/22.
//

import SFSafeSymbols
import SwiftUI
import XUI

struct ChatAccessoryBar: View {

	@Environment(ConversationViewModel.self) private var viewModel
	@Namespace private var chatNoticeView

	var body: some View {
		let manager = viewModel.manager
		HStack(alignment: .bottom) {
			if let accessory = manager.presentation.bottomAccessory {
				Spacer()
				if accessory == .scrollDownButton {
					AsyncButton {
						viewModel.send(.loadMore)
					} label: {
						Image(systemName: "chevron.down")
							.resizable()
							.scaledToFit()
							.padding(12)
							.frame(square: 40)
							.background(.windowBackground, in: .circle)
					}
					.transition(
						.scale(scale: 0).animation(.bouncy)
					)
				}
			}
		}
		.padding(.horizontal, 16)
		.geometryGroup()
	}
}
