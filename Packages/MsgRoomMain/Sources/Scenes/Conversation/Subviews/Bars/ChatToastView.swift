//
//  ChatToastView.swift
//  Msgr
//
//  Created by Aung Ko Min on 21/10/22.
//

import SFSafeSymbols
import SwiftUI
import XUI

struct ChatToastView: View {
	@Environment(ChatViewManager.self) private var manager

	var body: some View {
		HStack(alignment: .bottom) {
			Spacer()
			if manager.eventsManager.canShowScrollButton {
				CircleButton(.chevronDown) {
					manager.resetDatasource()
				}
				.transition(
					.scale(
						0,
						anchor: .trailing
					).animation(
						.bouncy(
							duration: 0.2
						)
					)
				)
			}
		}
		.padding(.horizontal, 8)
	}
}
