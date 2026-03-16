//
//  ChatScrollView.swift
//  Conversation
//
//  Created by Aung Ko Min on 11/3/26.
//

import Core
import Database
import Services
import SwiftUI
import XUI

struct ChatScrollView: View {

	@Environment(\.sharedNamespace) private var namespace
	var manager: ChatViewManager

	var body: some View {
		ScrollView(.vertical, showsIndicators: true) {
			LazyVStack(spacing: manager.conversationConfig.lineSpacing) {
				if manager.presentation.state.showContactInfo {
					ConversationHeaderView()
				}
				ForEach(manager.models.renderedModels) { viewModel in
					MsgCell(viewModel: viewModel)
						.environment(viewModel)
						.id(viewModel.id)
				}
			}
			.scrollTargetLayout()

		}
		.font(.system(size: UIFont.preferredFont(forTextStyle: .body).pointSize))
		.tint(Color.link.mix(with: Color.accentColor, by: 0.3))
		.animation(.interactiveSpring, value: manager.layout.selectedMsg)
		.onScrollPhaseChange { oldPhase, newPhase, context in
			manager.send(.onScrollPhaseChange(oldPhase, newPhase, context: context))
		}
		.onScrollGeometryChange(
			for: VScrollGeometry.self,
			of: { .init($0) }
		) { oldValue, newValue in
			manager.send(.onScrollGeometryChange(oldValue, newValue))
		}
		.scrollDismissesKeyboard(.never)
		.defaultScrollAnchor(.bottom, for: .sizeChanges)
		.equatable(by: manager.state)
		.scrollPosition(manager.scrollController.scrollPositionBindable, anchor: .none)

	}
}
