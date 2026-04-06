//
//  ConversationScene+OverlayBar.swift
//  Conversation
//
//  Created by Aung Ko Min on 23/3/26.
//

import SwiftUI
import Services
import Database
import XUI

struct ConversationSceneOverlayBar: View {

	@Environment(ChatManager.self) private var manager
	@LazyState private var composer: ChatComposer

	init() {
		_composer = .init(wrappedValue: .init())
	}
	var body: some View {
		VStack(alignment: .center, spacing: 8) {
			TopBar()
			FloatingDateView()
			Spacer()
			AccessoryBar()
			ComposeBar()
				.background {
					Color.clear.hidden().onGeometryChange(for: CGRect.self) { geometry in
						geometry.frame(in: .global)
					} action: { oldValue, newValue in
						manager.onBottomBarFrameChage(oldValue, newValue)
					}
				}
		}
		.environment(composer)
	}
}
