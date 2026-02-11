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
	let proxy: GeometryProxy
	@Environment(ChatViewManager.self) private var manager
	@Environment(\.selectedMsg) private var selectedMsg

	var body: some View {
		ScrollView(.vertical, showsIndicators: true) {
			MsgsScrollViewLayout(
				config: .init(
					manager.conversationConfig.lineSpacing,
					manager.conversationConfig.contentInsets,
					boundsWidth: proxy.insetAdjustedSize.width
				),
				layoutCache: manager.scrollController.messageLayoutCache
			) {
				if manager.presentation.showContactInfo {
					ConversationHeaderView()
				}
				ForEach(manager.models.ids, id: \.self) { id in
					if let viewModel = manager.models.cached(for: id) {
						MsgCell(viewModel: viewModel)
							.environment(viewModel)
							.id(viewModel.id)
							.onScrollVisibilityChange(threshold: 0.001) {
								[
									unowned viewModel
								] isVisible in
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
			}
		}
		.frame(width: proxy.insetAdjustedSize.width)
		.padding(.leading, proxy.safeAreaInsets.leading)
		.tint(Color.link.mix(with: Color.accentColor, by: 0.3))
		.transaction(value: manager.reloadID) {
			$0.animation = manager.scrollController.defaultAnimation
			$0.disablesAnimations = manager.scrollController.defaultAnimation == nil
			$0.addAnimationCompletion(criteria: .removed) {
				manager.scrollController.setDefaultAnimation(nil)
			}
		}
		.onScrollPhaseChange { oldPhase, newPhase, context in
			manager.scrollController.didChangeScrollPhase(oldPhase, newPhase, context)
		}
		.onScrollGeometryChange(
			for: VScrollGeometry.self,
			of: { .init($0) }
		) { oldValue, newValue in
			manager.scrollController
				.didChangeScrollGeometry(oldValue, newValue)
		}
		.scrollClipDisabled()
		.scrollDismissesKeyboard(.never)
		.scrollBounceBehavior(.always, axes: .vertical)
		.defaultScrollAnchor(.bottom, for: .sizeChanges)
		.scrollPosition(manager.scrollController.scrollPosition)
		.task {
			do {
				try await manager.onViewAppear()
			} catch {
				await manager.showError(error)
			}
		}
	}
}
