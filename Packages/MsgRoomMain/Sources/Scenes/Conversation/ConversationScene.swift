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
	@LazyState private var composer: ChatComposer
	@FocusState private var focusState: String?
	@Environment(Router.self) private var router
	@Environment(\.currentUser) private var currentUser
	@Namespace private var namespace

	public init(_ prefetchedData: ConversationInitializer.PrefetchedData) {
		_manager = .init(wrappedValue: .init(prefetchedData))
		_composer = .init(wrappedValue: .init())
	}

	public var body: some View {
		ZStack(alignment: .init(horizontal: .center, vertical: .bottom)) {
			manager.conversation.properties.theme.background.color
				.backgroundExtensionEffect()
			Image("adaptive")
				.resizable(resizingMode: .tile)
				.foregroundStyle(manager.conversation.theme.outgoingBubbleColor)
				.backgroundExtensionEffect()


			if let boundsWidth = manager.scrollController.inputAccessoryFrame?.size.width {
				MsgsScrollView(boundsWidth: boundsWidth)
					.safeAreaPadding(
						.init(
							top: ChatLayoutConstants.topBarHeight,
							leading: 0,
							bottom: ChatLayoutConstants.bottomBarHeight,
							trailing: 0
						)
					)
					.fullScreenCover(item: $manager.presentation.overlayItem) { frame in
						if let viewModel = manager.messageItems.element(withID: frame.id) {
							ChatOverlayView(item: frame)
								.environment(viewModel)
								.environment(manager)
								.presentationBackgroundInteraction(.enabled)
								.presentationBackground(.clear)
								.environment(\.viewIsVisible, true)
						}
					}
			}
			VStack {
				ChatTitleBar()
				FloatingDateView()
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

			VStack {
				ChatAccessoryBar()
				ComposeBar(composer: composer)
					.onGeometryChange(for: CGRect.self) { geometry in
						geometry.frame(in: .global)
					} action: { oldValue, newValue in
						manager.scrollController.didChangeInputAccessoryFrame(oldValue, newValue)
					}
			}
			.frame(maxWidth: .infinity, alignment: .bottom)
		}
		.containerRelativeFrame(.horizontal)
		.environment(manager)
		.environment(composer)
		.environment(\.conversationTheme, .init(manager.conversation))
		.environment(\.conversation, manager.conversation)
		.environment(\.attachmentFetcher, manager.attachments)
		.environment(\.selectedMsg, manager.presentation.selectedMsg)
		.environment(\.sharedFocusState, SharedFocusState($focusState))
		.environment(\.sharedNamespace, SharedNamespace(namespace))
		.environment(\.msgCellActions, MsgCellAction(action: handleMsgCellInteraction))
		.environment(\.layoutCache, manager.scrollController.messageLayoutCache)
		.task(priority: .background) {
			do {
				try await manager.onViewAppear()
			} catch {
				await manager.showError(error)
			}
		}
	}

}

private extension ConversationScene {
	func handleMsgCellInteraction(action: MsgCellAction.ActionType) {
		switch action {
		case let .onTapMsg(uid):
			handleTapMsg(with: uid)
		case let .onTapAvatar(id):
			handleTapAvatar(with: id)
		case let .onMarkMsg(data):
			handleMarkMsg(with: data)
		case let .onFocusMsgBubble(item):
			handleFocusMsgBubble(with: item)
		case let .onUploadedAttachments(msg):
			sendMsg(msg)
		case let .onReact(msg, reaction):
			handleReact(msg, reaction)
		}
	}

	func handleTapMsg(with uid: String) {
		manager.setSelectedMsg(uid)
	}

	func handleReact(_ msg: Message, _ reaction: String) {

		let currentUserID = currentUser.uid
		Task.detached {
			do {
				try await Task.sleep(seconds: 1)
				let reaction = Reaction.init(
					rawValue: reaction,
					senderID: currentUserID,
					date: .now
				)
				try await Socket.shared
					.send(
						.reaction(
							reaction: .init(
								reaction: reaction,
								msgID: msg.uid,
								conID: manager.conversation.uid
							)
						),
						conversation: manager.conversation
					)
			} catch {
				await manager.showError(error)
			}
		}
		manager.presentation.updateFocusedFrame(nil)
	}

	func handleTapAvatar(with id: String) {
		guard let viewModel = manager.messageItems.element(withID: id),
			  let contact = viewModel.sender()
		else {
			return
		}
		Router.shared.push(NavPath.contactDetails(contact))
	}
	func handleMarkMsg(with msg: Message) {
		manager.presentation.updateToast(.message(msg))
	}
	func handleFocusMsgBubble(with item: ChatOverlayView.Item) {
		manager.presentation.updateFocusedFrame(item)
	}
	func sendMsg(_ msg: Message) {
		Task {
			try await Socket.shared
				.send(.newMsg(rMsg: .init(msg)), conversation: manager.conversation)
		}
	}
}
