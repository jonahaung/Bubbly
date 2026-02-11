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
	@Environment(ChatViewManager.self) private var manager
	@Environment(ChatComposer.self) private var composer
	@Namespace private var chatNoticeView

	var body: some View {
		if let accessory = manager.presentation.bottomAccessory {
			HStack(alignment: .bottom) {
				Spacer()
				if accessory == .scrollDownButton {
					AsyncButton {
						manager.resetDatasource()
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
			.padding(.horizontal, 16)
			.geometryGroup()
			.transition(
				.scale(scale: 0).animation(.bouncy)
			)
		}
	}
}
