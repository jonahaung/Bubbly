//
//  ChatScrollView.swift
//  Conversation
//
//  Created by Aung Ko Min on 31/1/22.
//

import SwiftUI
import XUI
import Services
import Core
import Database

struct MsgsScrollView: View {

	@State var manager: ChatViewManager
	@Namespace private var namespace
	@Environment(\.conversation) private var conversation

	var body: some View {
		ScrollView {
			MsgsScrollViewLayout(
				spacing: manager.config.lineSpacing,
				boundsWidth: manager.currentLayoutWidth(),
				cache: manager.cache,
				contentInsets: manager.scrollManager.contentInsets
			) {
				if manager.eventsManager.showContactInfo {
					ConversationHeaderView()
				}
				ForEach(
					manager.cellItems, id: \.1.id
				) { index, viewModel  in
					let layout = manager.msgCellLayoutFor(viewModel.msg, index)

					if layout.showTimeSeparator {
						MsgCellTimeSeparaterView(id: viewModel.id, date: viewModel.msg.date)
					} else if layout.showTopPadding {
						MsgCellSpacer(id: viewModel.id)
					}

					let selectedMsg = manager.eventsManager.selectedMsg

					let isSelected = viewModel.id == selectedMsg?.id
					if isSelected {
						MsgCellHeader(msg: viewModel.msg)
					}
					MsgCell(
						viewModel: viewModel,
						bubble: layout.bubble
					)
					if isSelected {
						MsgCellFooter(msg: viewModel.msg)
					}
				}
			}
			.scrollTargetLayout()
			.geometryGroup()
		}
		.animation(
			.snappy,
			value: manager.conversation.seenMembers
		)
		.allowsHitTesting(manager.scrollManager.updatingState.isNotUpdating)
		.onScrollPhaseChange { oldPhase, newPhase, context in
			manager.scrollManager.handleScrollPhaseChange(oldPhase, newPhase, context)
		}
		.onScrollGeometryChange(
			for: ScrollGeometry.self,
			of: { $0 },
			action: { oldValue, newValue in
				manager.scrollManager.handleScrollGeometryChange(oldValue, newValue)
			}
		)
		.onScrollTargetVisibilityChange(
			idType: String.self,
			threshold: 0.001
		) { values in
			manager.handleVisibleIDsChange(values)
		}
		.scrollDismissesKeyboard(.immediately)
		.safeAreaPadding(.all, 0)
		.defaultScrollAnchor(.bottom, for: .initialOffset)
		.defaultScrollAnchor(.bottom, for: .sizeChanges)
		.scrollPosition(.constant(manager.scrollManager.scrollPosition), anchor: .center)
		.namespace(namespace)
		.task {
			await manager.onViewAppear()
		}
	}
}
