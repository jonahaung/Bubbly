//
//  Composer+MenuButton.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 30/1/26.
//

import PhotosUI
import SwiftUI

extension ComposeBar {
	struct ComposeBarMenuButton: View {
		@Environment(ChatComposer.self) private var composer: ChatComposer
		@Environment(\.sharedNamespace) private var namespace
		@Environment(\.sharedFocusState) private var sharedFocus

		var body: some View {
			Button {
				let isMenu = composer.source == .menu
				composer.source = isMenu ? .text : .menu
			} label: {
				TwoLinesShape()
					.frame(square: 24)
					.frame(square: 44)
					.background(
						.windowBackground,
						in: RoundedRectangle(cornerRadius: 22, style: .circular)
					)
			}
			.buttonStyle(.plain)
		}
	}
}
