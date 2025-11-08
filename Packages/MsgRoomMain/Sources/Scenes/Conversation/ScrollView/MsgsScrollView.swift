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

	let manager: ChatViewManager
	@Environment(\.screenSize) var screenSize
	@Namespace private var namespace
	@Environment(\.focusState) private var focusState

	var body: some View {
		ScrollView(.vertical, showsIndicators: true) {
			MsgsScrollViewLayout(
				config: .init(
					manager.config.lineSpacing,
					manager.config.contentInsets,
					containerSize: screenSize),
				layoutCache: manager.scrollManager.layoutCache
			) {
				if manager.eventsManager.showContactInfo {
					ConversationHeaderView()
						.frame(size: screenSize)
				}
				ForEach(manager.cellItems, id: \.id) { viewModel  in
					let layout = viewModel.layout
					if layout.showTimeSeparator {
						MsgCellTimeSeparaterView(id: viewModel.id, date: viewModel.msg.date)
					} else if layout.showTopPadding {
						MsgCellSpacer(id: viewModel.id)
					}
					if layout.isSelected {
						MsgCellHeader(msg: viewModel.msg)
					}
					MsgCell()
						.environment(viewModel)
					if layout.isSelected {
						MsgCellFooter(msg: viewModel.msg)
					}
				}
			}
			.geometryGroup()
			.scrollTargetLayout()
		}
		.onScrollPhaseChange { oldPhase, newPhase, context in
			manager.scrollManager.handleScrollPhaseChange(oldPhase, newPhase, context)
		}
		.onScrollGeometryChange(
			for: VScrollGeometry.self,
			of: { .init($0) },
			action: { oldValue, newValue in
				manager.scrollManager.handleScrollGeometryChange(oldValue, newValue)
			}
		)
		.onScrollTargetVisibilityChange(
			idType: String.self,
			threshold: 0.9
		) { values in
			manager.handleVisibleIDsChange(values)
		}
		.scrollClipDisabled(true)
		.scrollDismissesKeyboard(.immediately)
		.defaultScrollAnchor(.bottom, for: .initialOffset)
		.defaultScrollAnchor(.bottom, for: .sizeChanges)
		.scrollContentBackground(.hidden)
		.namespace(namespace)
		.equatable(by: manager.reloadID)
		.scrollPosition(.constant(manager.scrollManager.scrollPosition))
		.task(priority: .background) {
			await manager.onViewAppear()
		}
	}
}
