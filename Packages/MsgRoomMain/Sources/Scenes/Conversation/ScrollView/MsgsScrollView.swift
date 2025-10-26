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
	@Environment(\.conversation) private var conversation

	var body: some View {
		ScrollView {
			MsgsScrollViewLayout(
				config: .init(
					manager.config.lineSpacing,
					manager.config.contentInsets,
					containerSize: geometry.size),
				cacheContainer: manager.scrollManager.layoutCache
			) {
				if manager.eventsManager.showContactInfo {
					ConversationHeaderView()
						.frame(size: geometry.size)
				}
				ForEach(manager.cellItems, id: \.id) { viewModel  in
					let layout = manager.msgCellLayoutFor(viewModel.msg)
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
					manager
						.view(for: viewModel, bubble: layout.bubble)
						.eraseToAnyView()
					if isSelected {
						MsgCellFooter(msg: viewModel.msg)
					}
				}
			}
			.gesture(tapGesture)
			.geometryGroup()
			.scrollTargetLayout()
		}
		.namespace(namespace)
		.scrollDismissesKeyboard(.interactively)
		.defaultScrollAnchor(.bottom, for: .initialOffset)
		.defaultScrollAnchor(.bottom, for: .sizeChanges)
		.scrollPosition(.constant(manager.scrollManager.scrollPosition))
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
		.onPressingChanged(in: .global) { location in
			manager.handlePressingChanged(location)
		}
		.task {
			await manager.onViewAppear()
		}
	}

	private var tapGesture: some Gesture {
		SpatialTapGesture(count: 2, coordinateSpace: .local)
			.onEnded { value in
				manager.handleTappingChanged(value.location)
			}

	}
}
