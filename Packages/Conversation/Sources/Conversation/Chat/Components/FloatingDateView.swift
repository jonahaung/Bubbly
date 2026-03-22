//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

//
//  FloatingDateView.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 27/4/25.
//
import SwiftUI
import XUI

struct FloatingDateView: View {

	@Environment(ChatViewManager.self) private var manager

    var body: some View {
		if let dateText = manager.presentation.state.dateText {
			Text(dateText)
				.font(.footnote.bold())
				.lineHeight(.normal)
				.lineSpacing(0)
				.padding(.horizontal, 12)
				.padding(.vertical, 4)
				.background(.background, in: .capsule)
		}
    }
}
extension Text {
	func earthquake(
		amount: Double,
		blur: Bool = false
	) -> some View {
		self.textRenderer(
			EarthquakeRenderer(
				moveAmount: amount,
				shouldBlur: blur
			)
		)
	}
}
