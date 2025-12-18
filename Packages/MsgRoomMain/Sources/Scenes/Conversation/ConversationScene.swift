//
//  ConversationScene.swift
//  MsgRoom
//
//  Created by Aung Ko Min on 12/3/24.
//

import Core
import Database
import Services
import SwiftUI
import XUI

public struct ConversationScene: View {

	@LazyState private var manager: ChatViewManager
	@FocusState private var isFieldFocused: Bool

	public init(_ prefetchedData: ConversationInitializer.PrefetchedData) {
		_manager = .init(wrappedValue: .init(prefetchedData))

	}

	public var body: some View {
		ZStack(alignment: .leading) {
			background
			MsgsScrollView()
			VStack {
				FloatingDateView()
				Spacer()
				ChatToastView()
			}
		}
		.safeAreaInset(edge: .top, spacing: 0) {
			ChatTopBarView()
		}
		.safeAreaInset(edge: .bottom, spacing: 0) {
			ChatInputBar()
				.onGeometryChange(for: CGRect.self) { geometry in
					geometry.frame(in: .global)
				} action: { oldValue, newValue in
					manager.scrollManager.handleBottomBarFrameChange(oldValue, newValue)
				}
		}
		.background(
			manager.conversation.properties.theme.background.color,
			ignoresSafeAreaEdges: .all
		)
		.fullScreenCover(item: $manager.eventsManager.overlayItem) { frame in
			if let viewModel = manager.data.element(withID: frame.id) {
				ChatOverlayView(item: frame, viewModel: viewModel)
					.ignoresSafeArea(.container)
					.environment(manager)
					.presentationBackgroundInteraction(.disabled)
					.presentationBackground(.clear)
			}
		}
		.receiveMsgCellInteraction { action in
			MainActor.assumeIsolated {
				handleMsgCellInteraction(action: action)
			}
		}
		.environment(manager)
		.environment(\.sharedFocus, SharedFocusState($isFieldFocused))
		.environment(\.conversationTheme, .init(manager.conversation))
		.environment(\.conversation, manager.conversation)
		.environment(\.asyncFetcher, manager.asyncFetcher)
		.environment(\.selectedMsg, manager.eventsManager.selectedMsg)
		.task(priority: .background) {
			await manager.onViewAppear()
		}
	}

	private func handleMsgCellInteraction(action: MsgCellInteraction.Action) {
		switch action {
			case let .onTapMsg(uid):
				handleTapMsg(with: uid)
			case let .onTapAvatar(id):
				handleTapAvatar(with: id)
			case let .onMarkMsg(data):
				handleMarkMsg(with: data)
			case let .onFocusMsgBubble(item):
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
					if let msgCellViewModel = manager.data.element(withID: msg.uid) {
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
		guard let viewModel = manager.data.element(withID: id),
			  let contact = viewModel.sender()
		else {
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
		.foregroundStyle(.tertiary)
		.ignoresSafeArea(.all)
		.equatable(by: true)
}
