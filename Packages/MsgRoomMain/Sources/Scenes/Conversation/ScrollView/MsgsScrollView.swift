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

	@Namespace private var namespace
	@Environment(ChatViewManager.self) private var manager
	@Environment(\.selectedMsg) private var selectedMsg
	@Environment(\.sharedFocus) private var sharedFocus

	var body: some View {
		GeometryReader { proxy in
			ScrollView(.vertical, showsIndicators: true) {
				MsgsScrollViewLayout(
					config: .init(
						manager.config.lineSpacing,
						manager.config.contentInsets,
						containerSize: proxy.size
					),
					layoutCache: manager.scrollManager.layoutCache
				) {
					if manager.eventsManager.showContactInfo {
						ConversationHeaderView()
							.frame(size: proxy.size)
					}

					ForEach(manager.data.array, id: \.id) { cellViewModel in
						let isSelected = cellViewModel.id == selectedMsg?.id
						if cellViewModel.layout.showTimeSeparator {
							MsgCellTimeSeparaterView(
								id: cellViewModel.id,
								date: cellViewModel.msg.date
							)
						} else if cellViewModel.layout.showTopPadding {
							MsgCellSpacer(
								id: cellViewModel.id
							)
						}
						if isSelected {
							MsgCellHeader(
								msg: cellViewModel.msg
							)
						}
						MsgCell()
							.environment(cellViewModel)
						if isSelected {
							MsgCellFooter(
								msg: cellViewModel.msg
							)
						}
					}
				}
//				.allowsTightening(true)
				.namespace(namespace)
				.animation(.snappy, value: manager.conversation.properties.seenMembers)
				.geometryGroup()
				.scrollTargetLayout()
			}
			.animation(.interactiveSpring, value: selectedMsg)
			.onScrollPhaseChange { oldPhase, newPhase, context in
				manager.scrollManager
					.handleScrollPhaseChange(oldPhase, newPhase, context)
				defocusIfNeeded(oldPhase, newPhase)

			}
			.onScrollGeometryChange(for: VScrollGeometry.self, of: { .init($0) }) { oldValue, newValue in
				manager.scrollManager
					.handleScrollGeometryChange(oldValue, newValue)
			}
			.onScrollTargetVisibilityChange(
				idType: String.self,
				threshold: 0.001
			) { values in
				manager.handleVisibleIDsChange(values)
			}
			.scrollDismissesKeyboard(.never)
			.defaultScrollAnchor(.bottom, for: .sizeChanges)
			.equatable(by: manager.reloadID)
			.scrollPosition(
				.init(
					get: {
						manager.scrollManager.scrollPosition
					},
					set: { _ in
					}
				)
			)
		}
	}

	func defocusIfNeeded(_ oldPhase: ScrollPhase, _ newPhase: ScrollPhase) {
		if let sharedFocus {
			if sharedFocus.isFocused {
				if oldPhase == .interacting && newPhase == .decelerating {
					sharedFocus.defocus()
				}
			}
		}
	}
}
