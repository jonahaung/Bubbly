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

	@LazyState private var manager: ChatViewManager
	@FocusState private var isFieldFocused: Bool

	public init(_ prefetchedData: ConversationInitializer.PrefetchedData) {
		_manager = .init(wrappedValue: .init(prefetchedData))
	}

	public var body: some View {
		ZStack {
			background
			MsgsScrollView(manager: manager)
			overlayViews
		}
		.fullScreenCover(item: $manager.eventsManager.overlayItem) { frame in
			if let viewModel = manager.cellItems.viewModel(of: frame.id) {
				ChatOverlayView(item: frame, viewModel: viewModel)
					.ignoresSafeArea(.container)
					.environment(manager)
					.presentationBackground(.clear)
					.presentationBackgroundInteraction(.disabled)

			}
		}
		.background(
			manager.conversation.theme.background.color,
			ignoresSafeAreaEdges: .all
		)
		.receiveMsgCellInteraction { action in
			MainActor.assumeIsolated {
				handleMsgCellInteraction(action: action)
			}
		}
		.environment(\.conversationTheme, .init(manager.conversation))
		.environment(\.attachmentFetcher, manager.attachmentFetcher)
		.environment(manager)
		.environment(\.focusState, SharedFocusState($isFieldFocused))
	}

	private var overlayViews: some View {
		VStack(spacing: 0) {
			ChatTopBarView()
			FloatingDateView()
			Spacer()
				.hidden()
			ChatToastView()
			ChatInputBar()
				.background {
					Color.clear
						.onGeometryChange(for: CGRect.self) { geometry in
							geometry.frame(in: .global).integral
						} action: { oldValue, newValue in
							manager.scrollManager.handleBottomBarFrameChange(oldValue, newValue)
						}
				}
		}
		.layoutPriority(1)
		.geometryGroup()
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
					if let msgCellViewModel = manager.cellItems.viewModel(of: msg.uid) {
						msgCellViewModel.update(with: msg)
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
		guard let viewModel = manager.cellItems.first(where: { $0.id == id }),
			  let contact = viewModel.sender() else {
			return
		}
		Router.shared.push(NavPath.contactDetails(contact))
	}

	private func handleMarkMsg(with msg: Message) {
		manager.eventsManager.updateToast(.message(msg))
	}

	private func handleFocusMsgBubble(with item: ChatOverlayView.Item) {
		manager.eventsManager.updateFocusedFrame(item)
	}

	private let background: some View = Image("adaptive")
		.resizable(resizingMode: .tile)
		.foregroundStyle(.secondary)
		.equatable(by: true)
}
