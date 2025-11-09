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
					containerSize: screenSize
				),
				layoutCache: manager.scrollManager.layoutCache
			) {
				if manager.eventsManager.showContactInfo {
					ConversationHeaderView()
						.frame(size: screenSize)
				}
				ForEach(
					manager.cellItems,
					id: \.id
				) {
					let layout = $0.layout
					if layout.showTimeSeparator {
						MsgCellTimeSeparaterView(
							id: $0.id,
							date: $0.msg.date
						)
					} else if layout.showTopPadding {
						MsgCellSpacer(
							id: $0.id
						)
					}
					if layout.isSelected {
						MsgCellHeader(
							msg: $0.msg
						)
					}
					MsgCell()
						.environment(
							$0
						)
					if layout.isSelected {
						MsgCellFooter(
							msg: $0.msg
						)
					}
				}
			}
			.geometryGroup()
			.scrollTargetLayout()
		}
		.onScrollPhaseChange {
			oldPhase,
			newPhase,
			context in
			manager.scrollManager
				.handleScrollPhaseChange(
					oldPhase,
					newPhase,
					context
				)
		}
		.onScrollGeometryChange(
			for: VScrollGeometry.self,
			of: {
				.init($0)
			},
			action: {
				oldValue,
				newValue in
				manager.scrollManager
					.handleScrollGeometryChange(
						oldValue,
						newValue
					)
			}
		)
		.onScrollTargetVisibilityChange(
			idType: String.self,
			threshold: 0.001
		) { values in
			manager.handleVisibleIDsChange(values)
		}
		.scrollClipDisabled(true)
		.scrollDismissesKeyboard(.interactively)
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
