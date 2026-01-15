//
//  MsgsScrollView.swift
//  Conversation
//
//  Created by Aung Ko Min on 31/1/22.
//

import Core
import Database
import Services
import SwiftUI
import XUI

struct MsgsScrollView: View {

	let boundsWidth: CGFloat
	@Environment(ChatViewManager.self) private var manager
	@Environment(\.selectedMsg) private var selectedMsg
	@Environment(\.sharedFocusState) private var sharedFocus

	var body: some View {
		ScrollView(.vertical, showsIndicators: true) {
			MsgsScrollViewLayout(
				config: .init(
					manager.conversationConfig.lineSpacing,
					manager.conversationConfig.contentInsets,
					boundsSize: .init(
						width: boundsWidth,
						height: .infinity
					)
				),
				layoutCache: manager.scrollController.messageLayoutCache
			) {
				if manager.presentation.showContactInfo {
					ConversationHeaderView()
				}
				ForEach(manager.messageItems.array, id: \.id) { viewModel in
					MsgCell()
						.environment(viewModel)
						.id(viewModel.id)
						.onScrollVisibilityChange(threshold: 0.001) { [unowned viewModel] isVisible in
							viewModel.setVisibility(isVisible)
							if viewModel.layout.showTimeSeparator {
								manager.presentation.updateFloatingDate(viewModel.msg.date)
							}
						}
						.layoutValue(
							key: MsgLayoutValueKey.self,
							value: viewModel.msg.layoutValue()
						)
				}
			}
			.scrollTargetLayout(isEnabled: false)
			.geometryGroup()
		}
		.transaction(value: manager.reloadID) {
			$0.animation = manager.scrollController.defaultAnimation
			$0.disablesAnimations = manager.scrollController.defaultAnimation == nil
			$0.addAnimationCompletion(criteria: .removed) {
				manager.scrollController.setDefaultAnimation(nil)
			}
		}
		.onScrollPhaseChange { oldPhase, newPhase, context in
			manager.scrollController.didChangeScrollPhase(oldPhase, newPhase, context)
			defocusIfNeeded(oldPhase, newPhase)
		}
		.onScrollGeometryChange(for: VScrollGeometry.self, of: { .init($0) }) { oldValue, newValue in
			if newValue.offsetY+newValue.boundsHeight > newValue.contentHeight {
				if manager.scrollController.scrollState == .interacting, sharedFocus?.value == nil {
					sharedFocus?.focus(ComposeSource.text.rawValue)
				}
			} else {
				manager.scrollController
					.didChangeScrollGeometry(oldValue, newValue)
			}
		}
		.scrollDismissesKeyboard(.never)
		.scrollBounceBehavior(.basedOnSize, axes: .vertical)
		.defaultScrollAnchor(.bottom, for: .sizeChanges)
		.equatable(by: manager.reloadID)
		.scrollPosition(
			.init(
				get: { manager.scrollController.scrollTarget },
				set: { newValue in }
			)
		)
	}

	func defocusIfNeeded(_ oldPhase: ScrollPhase, _ newPhase: ScrollPhase) {
		if oldPhase == .idle && newPhase == .interacting {
			if sharedFocus?.isFocused(for: ComposeSource.text.rawValue) == true {
				sharedFocus?.defocus()
			}
		}
	}
}
