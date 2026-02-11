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
		ZStack(alignment: .trailing) {
			Image("adaptive")
				.resizable(resizingMode: .tile)
				.clipped()
				.background(
					manager.conversation.properties.theme.background.color,
					ignoresSafeAreaEdges: .all
				)
				.foregroundStyle(
					Color.accentColor
						.mix(with: manager.conversation.theme.outgoingBubbleColor, by: 0.7)
				)
				.backgroundExtensionEffect()
				.equatable(by: 1)

			if let accessoryFrame = manager.scrollController.inputAccessoryFrame {
				GeometryReader { proxy in
					MsgsScrollView(proxy: proxy)
						.safeAreaPadding(.bottom, accessoryFrame.height)
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
			}
			VStack {
				ChatTitleBar()
				FloatingDateView()
				Spacer()
				ChatAccessoryBar()
				ComposeBar(composer: composer)
					.flexible(.horizontal)
					.onGeometryChange(for: CGRect.self) { geometry in
						geometry.frame(in: .global).integral
					} action: { oldValue, newValue in
						manager.scrollController.didChangeInputAccessoryFrame(oldValue, newValue)
					}
			}
		}
		.toolbarVisibility(.hidden, for: .navigationBar)
		.environment(manager)
		.environment(composer)
		.environment(\.backgroundColor, manager.conversation.theme.background.color)
		.environment(\.conversationTheme, .init(manager.conversation))
		.environment(\.conversation, manager.conversation)
		.environment(\.attachmentFetcher, manager.attachments)
		.environment(\.selectedMsg, manager.presentation.selectedMsg)
		.environment(\.sharedFocusState, SharedFocusState($focusState))
		.environment(\.sharedNamespace, SharedNamespace(namespace))
		.environment(\.msgCellActions, MsgCellAction(action: handleMsgCellInteraction))
		.equatable(by: manager.reloadID)
		.task {
			do {
				try await manager.onViewAppear()
			} catch {
				await manager.showError(error)
			}
		}
	}
}

extension ConversationScene {
	fileprivate func handleMsgCellInteraction(action: MsgCellAction.ActionType) {
		switch action {
		case .onTapMsg(let uid):
			handleTapMsg(with: uid)
		case .onTapAvatar(let id):
			handleTapAvatar(with: id)
		case .onMarkMsg(let data):
			handleMarkMsg(with: data)
		case .onFocusMsgBubble(let item):
			handleFocusMsgBubble(with: item)
		case .onUploadedAttachments(let msg):
			sendMsg(msg)
		case .onReact(let msg, let reaction):
			handleReact(msg, reaction)
		}
	}

	fileprivate func handleTapMsg(with uid: String) {
		manager.setSelectedMsg(uid)
	}

	fileprivate func handleReact(_ msg: Message, _ reaction: ReactionType) {
		let currentUserID = currentUser.uid
		Task.detached {
			do {
				try await Task.sleep(seconds: 1)
				let reaction = Reaction(
					rawValue: reaction.rawValue,
					senderID: currentUserID,
					date: .now
				)
				await Socket
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

	fileprivate func handleTapAvatar(with id: String) {
		guard let viewModel = manager.models.element(withID: id),
			let contact = viewModel.sender()
		else {
			return
		}
		if let url = DeepLinkCoordinator.shared.url(for: .profile(id: contact.uid)) {
			UIApplication.shared.open(url)
		}
	}

	fileprivate func handleMarkMsg(with msg: Message) {
		manager.presentation.updateToast(.message(msg))
	}

	fileprivate func handleFocusMsgBubble(with item: ChatOverlayView.Item) {
		manager.presentation.updateFocusedFrame(item)
	}

	fileprivate func sendMsg(_ msg: Message) {
		Task {
			await Socket
				.send(.newMsg(rMsg: .init(msg)), conversation: manager.conversation)
		}
	}
}
