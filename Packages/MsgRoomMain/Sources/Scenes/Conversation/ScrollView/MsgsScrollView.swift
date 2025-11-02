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
	let geometry: GeometryProxy
	@Namespace private var namespace
	@Environment(\.focusState) private var focusState

	var body: some View {
		ScrollView(.vertical, showsIndicators: true) {
			MsgsScrollViewLayout(
				config: .init(
					manager.config.lineSpacing,
					manager.config.contentInsets,
					containerSize: geometry.size),
				layoutCache: manager.scrollManager.layoutCache
			) {
				if manager.eventsManager.showContactInfo {
					ConversationHeaderView()
						.frame(size: geometry.size)
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
			.equatable(by: manager.cellItems.count.value + (manager.eventsManager.selectedMsg?.id ?? ""))
		}
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
			threshold: 0.01
		) { values in
			manager.handleVisibleIDsChange(values)
		}
		.scrollClipDisabled(true)
		.scrollDismissesKeyboard(.immediately)
		.defaultScrollAnchor(.bottom, for: .initialOffset)
		.defaultScrollAnchor(.bottom, for: .sizeChanges)
		.scrollPosition(.constant(manager.scrollManager.scrollPosition))
		.scrollContentBackground(.hidden)
		.namespace(namespace)
		.task {
			await manager.onViewAppear()
		}
	}
}
