//
//  ConversationScene.swift
//  MsgRoom
//
//  Created by Aung Ko Min on 12/3/24.
//

import SwiftUI
import Database
import Services
import XUI
import Core

public struct ConversationScene: View {
	private let manager: ChatViewManager

	public init(_ prefetchedData: ConversationInitializer.PrefetchedData) {
		manager = .init(prefetchedData)
	}

	public var body: some View {
		ZStack {
			if !showFullScreen {
				Image("adaptive")
					.resizable()
					.foregroundStyle(.secondary)
					.ignoresSafeArea()
					.layoutPriority(-1)
					.equatable(by: true)
			}
			if manager.currentLayoutWidth() > 0 {
				MsgsScrollView(manager: manager)
			}
			overlayViews
			focusedItemOverlay
		}
		.background(
			manager.conversation.theme.background.color,
			ignoresSafeAreaEdges: .all
		)
		.animation(.interpolatingSpring(duration: 0.28), value: showFullScreen)
		.receiveMsgCellInteraction { action in
			MainActor.assumeIsolated {
				handleMsgCellInteraction(action: action)
			}
		}
		.environment(\.eventsManager, manager.eventsManager)
		.environment(\.conversation, manager.conversation)
		.environment(manager)
		.toolbarVisibility(.hidden, for: .navigationBar, .tabBar)
	}

	private var showFullScreen: Bool {
		manager.eventsManager.focusedFrame != nil
	}
	private var overlayViews: some View {
		VStack {
			ChatTopBarView()
			FloatingDateView()
			Spacer()
			ChatToastView()
			ChatInputBar()
				.onGeometryChange(for: CGRect.self) { geometry in
					geometry.frame(in: .global)
				} action: { oldValue, newValue in
					manager.scrollManager.handleBottomBarFrameChange(oldValue, newValue)
				}
		}
		.opacity(showFullScreen ? 0 : 1)
		.statusBarHidden(showFullScreen)
		.geometryGroup()
		.layoutPriority(1)
	}

	@ViewBuilder
	private var focusedItemOverlay: some View {
		if let focusedItem = manager.eventsManager.focusedFrame {
			ChatOverlayView(item: focusedItem)
				.ignoresSafeArea()
				.environment(manager)
		}
	}

	private func handleMsgCellInteraction(action: MsgCellInteraction.Action) {
		switch action {
		case .onTapMsg(let uid):
			handleTapMsg(with: uid)
		case .onTapAvatar(let id):
			handleTapAvatar(with: id)
		case .onMarkMsg(let data):
			handleMarkMsg(with: data)
		case .onFocusMsgBubble(let item):
			handleFocusMsgBubble(with: item)
		}
	}

	private func handleRefreshMsg(_ uid: String) {
		Task {
			do {
				guard let msg = try await Store.shared.msgStore.fetch(uid: uid) else {
					fatalError()
				}
				await MainActor.run {
					if let msgCellViewModel = manager.cellItems.first(where: { $0.1.msg.uid == uid }) {
						msgCellViewModel.1.update(with: msg)
					}
				}
			} catch {
				await manager.showError(error)
			}
		}
	}

	private func handleTapMsg(with uid: String?) {
		if let uid {
			manager.setSelectedMsg(uid)
		}
	}

	private func handleTapAvatar(with id: String) {
		guard let viewModel = manager.cellItems.first(where: { $0.1.id == id }),
			  let contact = viewModel.1.sender() else {
			return
		}
		Router.shared.push(NavPath.contactDetails(contact))
	}

	private func handleMarkMsg(with msg: MsgSnapshot) {
		manager.eventsManager.updateToast(.message(msg))
	}

	private func handleFocusMsgBubble(with item: ChatOverlayView.Item) {
		manager.eventsManager.updateFocusedFrame(item)
	}
}
