//
//  ScrollDownButton.swift
//  Msgr
//
//  Created by Aung Ko Min on 21/10/22.
//

import SwiftUI
import XUI
import SFSafeSymbols

struct ChatToastView: View {

	@Environment(ChatViewManager.self) private var manager

	public var body: some View {
		HStack(alignment: .bottom) {
			Text("\(manager.scrollManager.offsetY, format: .number.precision(.fractionLength(0)))")
				.font(.caption.bold())
			Spacer()
			if manager.eventsManager.canShowScrollButton {
				CircleButton(.chevronDown) {
					manager.resetDatasource()
				}
				.transition(.scale(0, anchor: .trailing).animation(.bouncy(duration: 0.2)))
			}
		}
		.padding(.horizontal, 8)
	}
}
