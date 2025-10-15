//
//  ScrollDownButton.swift
//  Msgr
//
//  Created by Aung Ko Min on 21/10/22.
//

import SwiftUI
import XUI

struct ChatToastView: View {
	
	@Environment(ChatViewManager.self) private var manager

	public var body: some View {
		HStack(alignment: .bottom) {
			Spacer()
			if manager.scrollManager.scrolledPosition != .atBottom {
				CircleButton(.chevronDown) {
					manager.resetDatasource()
				}
				.equatable(by: 1)
				.transition(.scale(0, anchor: .trailing).animation(.bouncy))
			}
		}
		.padding(.horizontal, 8)
	}
}
