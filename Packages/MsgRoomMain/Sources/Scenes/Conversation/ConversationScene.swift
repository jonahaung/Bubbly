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

	@LazyState private var viewModel: ConversationViewModel
	@Environment(\.dismiss) private var dismiss
	@FocusState private var focusState: String?
	@Namespace private var namespace

	public init(_ prefetchedData: ConversationInitializer.PrefetchedData) {
		_viewModel = .init(wrappedValue: .init(prefetchedData))
	}

	public var body: some View {
		let manager = viewModel.manager
		let composer = viewModel.composer
		ZStack(alignment: .trailing) {
			Image("adaptive")
				.resizable(resizingMode: .tile)
				.clipped()
				.background(
					viewModel.state.conversation.properties.theme.background.color,
					ignoresSafeAreaEdges: .all
				)
				.foregroundStyle(
					AngularGradient(colors: Color.adaptableColors, center: .center)
				)
				.backgroundExtensionEffect()
				.equatable(by: 1)

			if let accessoryFrame = manager.scrollController.inputAccessoryFrame {
				GeometryReader { proxy in
					MsgsScrollView(proxy: proxy)
						.safeAreaPadding(.bottom, accessoryFrame.height)
						.task {
							viewModel.send(.appear)
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

			if let frame = manager.presentation.overlayItem, let viewModel = manager.models.element(
				withID: frame.id
			) {
				ChatOverlayView(item: frame)
					.environment(viewModel)
					.environment(\.conversation, self.viewModel.state.conversation)
					.environment(\.viewIsVisible, true)
			}
		}
		.toolbarVisibility(.hidden, for: .navigationBar)
		.environment(viewModel)
		.environment(manager)
		.environment(composer)
		.environment(\.backgroundColor, viewModel.state.conversation.theme.background.color)
		.environment(\.conversationTheme, .init(viewModel.state.conversation))
		.environment(\.conversation, viewModel.state.conversation)
		.environment(\.attachmentFetcher, manager.attachments)
		.environment(\.selectedMsg, viewModel.state.selectedMsg)
		.environment(\.sharedFocusState, SharedFocusState($focusState))
		.environment(\.sharedNamespace, SharedNamespace(namespace))
		.environment(\.msgCellActions, MsgCellAction(action: handleMsgCellInteraction))
		.equatable(by: viewModel.state.reloadID)
		
	}
}

extension ConversationScene {
	fileprivate func handleMsgCellInteraction(action: MsgCellAction.ActionType) {
		switch action {
		case .onTapMsg(let uid):
			viewModel.send(.tapMessage(uid))
		case .onTapAvatar(let id):
			viewModel.send(.tapAvatar(id))
		case .onMarkMsg(let data):
			viewModel.send(.markMessage(data))
		case .onFocusMsgBubble(let item):
			viewModel.send(.focusMsgBubble(item))
		case .onUploadedAttachments(let msg):
			viewModel.send(.uploadedAttachments(msg))
		case .onReact(let msg, let reaction):
			viewModel.send(.react(msg, reaction))
		}
	}
}
