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
	@State private var draggedOffset = CGFloat.zero
	@State private var draggedLimitReached = false
	var body: some View {
		ScrollView {
			MsgsScrollViewLayout(
				spacing: manager.config.lineSpacing,
				boundsWidth: manager.scrollManager.boundsWidth,
				cacheContainer: manager.cache,
				contentInsets: manager.config.contentInsets
			) { heightDiff in
				print(heightDiff)
			} {
				if manager.eventsManager.showContactInfo {
					ConversationHeaderView()
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
					MsgCell(
						viewModel: viewModel,
						bubble: layout.bubble
					)

					if isSelected {
						MsgCellFooter(msg: viewModel.msg)
					}
				}
			}
			.gesture(tapGesture)
			.scrollTargetLayout()
			.geometryGroup()
		}
		.transformEffect(.init(translationX: draggedOffset, y: 0))
		.transaction(value: manager.eventsManager.selectedMsg) { value in
			value.animation = .interactiveSpring
			value.scrollPositionUpdatePreservesVelocity = true
			value.scrollContentOffsetAdjustmentBehavior = .disabled
			value.tracksVelocity = true
		}
		.animation(
			.snappy,
			value: manager.conversation.seenMembers
		)
		.onPressingChanged { location in
			manager.handlePressingChanged(location)
		}
		.scrollDisabled(manager.scrollManager.updatingState.isUpdating)
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
		.scrollContentBackground(.hidden)
		.scrollDismissesKeyboard(.immediately)
		.defaultScrollAnchor(.bottom, for: .initialOffset)
		.defaultScrollAnchor(.bottom, for: .sizeChanges)
		.scrollPosition(.constant(manager.scrollManager.scrollPosition), anchor: .center)
		.namespace(namespace)
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
