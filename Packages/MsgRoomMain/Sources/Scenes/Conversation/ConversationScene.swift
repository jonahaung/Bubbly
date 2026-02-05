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
	@Environment(\.typography) private var typography

	public init(_ prefetchedData: ConversationInitializer.PrefetchedData) {
		_manager = .init(wrappedValue: .init(prefetchedData))
		_composer = .init(wrappedValue: .init(id: prefetchedData.conversation.uid))
	}

	public var body: some View {
		ZStack {
			ZStack {
				manager.conversation.properties.theme.background.color
				Image("adaptive")
					.resizable(resizingMode: .tile)
					.clipped()
					.foregroundStyle(
						Color.accentColor
							.mix(with: manager.conversation.theme.outgoingBubbleColor, by: 0.7)
					)
			}
			.compositingGroup()
			.backgroundExtensionEffect()

			if let accessoryFrame = manager.scrollController.inputAccessoryFrame {
				MsgsScrollView(boundsWidth: accessoryFrame.width)
					.safeAreaPadding(
						.init(
							top: ChatLayoutConstants.topBarHeight,
							leading: 0,
							bottom: ChatLayoutConstants.bottomBarHeight,
							trailing: 0
						)
					)
					.fullScreenCover(item: $manager.presentation.overlayItem) { frame in
						if let viewModel = manager.models.element(withID: frame.id) {
							LazyLoadedView {
								ChatOverlayView(item: frame)
									.environment(viewModel)
									.environment(\.conversation, manager.conversation)
									.presentationBackgroundInteraction(.enabled)
									.presentationBackground(.clear)
									.environment(\.viewIsVisible, true)
							}
						}
					}

			}
			VStack {
				ChatTitleBar()
				FloatingDateView()
				Spacer()
				ChatAccessoryBar()
				ComposeBar(composer: composer)
					.onGeometryChange(for: CGRect.self) { geometry in
						geometry.frame(in: .global)
					} action: { oldValue, newValue in
						manager.scrollController.didChangeInputAccessoryFrame(oldValue, newValue)
					}
			}
		}
		.toolbarVisibility(.hidden, for: .navigationBar)
		.equatable(by: manager.reloadID)
		.environment(manager)
		.environment(composer)
		.environment(\.conversationTheme, .init(manager.conversation))
		.environment(\.conversation, manager.conversation)
		.environment(\.attachmentFetcher, manager.attachments)
		.environment(\.selectedMsg, manager.presentation.selectedMsg)
		.environment(\.sharedFocusState, SharedFocusState($focusState))
		.environment(\.sharedNamespace, SharedNamespace(namespace))
		.environment(\.msgCellActions, MsgCellAction(action: handleMsgCellInteraction))

		.task {
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

	func handleReact(_ msg: Message, _ reaction: ReactionType) {

		let currentUserID = currentUser.uid
		Task.detached {
			do {
				try await Task.sleep(seconds: 1)
				let reaction = Reaction.init(
					rawValue: reaction.rawValue,
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

		guard let viewModel = manager.models.element(withID: id),
			  let contact = viewModel.sender()
		else {
			return
		}
		if let url = DeepLinkCoordinator.shared.url(for: .profile(id: contact.uid)) {
			UIApplication.shared.open(url)
		}
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
