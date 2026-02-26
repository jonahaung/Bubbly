import Core
import Database
import Services
import SwiftUI
import XUI

public struct ConversationScene: View {

	@Environment(\.dismiss) private var dismiss
	@FocusState private var focusState: String?
	@Namespace private var namespace
	let coordinator: AppCoordinator
	@LazyState private var manager: ChatViewManager
	@LazyState private var composer: ChatComposer

	public init(_ prefetchedData: ConversationInitializer.PrefetchedData, coordinator: AppCoordinator) {
		_manager = .init(wrappedValue: .init(prefetchedData))
		_composer = .init(wrappedValue: .init(id: prefetchedData.conversation.uid))
		self.coordinator = coordinator
	}

	public var body: some View {
		ZStack(alignment: .bottom) {
			ConversationSceneBackground(color: manager.conversation.theme.background.color)

			if let frame = manager.scrollController.inputAccessoryFrame, frame.maxX > 0 {
				MsgsScrollView(manager: manager)
					.safeAreaPadding(.bottom, ChatLayoutConstants.bottomBarHeight)
					.task {
						manager.send(.onVisibilityChange(visibility: .visible))
					}
					
			}
			VStack(spacing: 0) {
				ChatTitleBar()
				FloatingDateView()
				Spacer()
				ChatAccessoryBar()
				ComposeBar(composer: composer)
					.onGeometryChange(for: CGRect.self) { geometry in
						let frame = geometry.frame(in: .global)
						let insets = geometry.safeAreaInsets
						let uiInsets = UIEdgeInsets(
							top: 0,
							left: insets.leading,
							bottom: 0,
							right: insets.trailing
						)
						return frame.inset(by: uiInsets)
					} action: { oldValue, newValue in
						guard oldValue != newValue else { return }
						manager.layoutManager.config.boundsWidth = newValue.width
						manager.send(.onBottomBarFrameChage(oldValue, newValue))
					}
			}
			.flexible(.all)
			.layoutPriority(1)

//			Circle().fill(Color.yellow)
//				.frame(width: 30, height: 30)
//				.offset(x: 15)
//				.matchedGeometryEffect(
//					id: manager.matchedID,
//					in: namespace,
//					properties: .position,
//					anchor: .trailing,
//					isSource: true
//				)

			if let frame = manager.presentation.overlayItem,
			   let overlayViewModel = manager.models.element(withID: frame.id) {
				ChatOverlayView(item: frame)
					.environment(overlayViewModel)
					.environment(\.conversation, manager.conversation)
					.environment(\.viewIsVisible, true)
			}
		}
		.task {
			try? await manager.onViewAppear()
		}
		.toolbarVisibility(.hidden, for: .navigationBar)
		.environment(manager)
		.environment(composer)
		.environment(\.conversationTheme, manager.theme)
		.environment(\.conversation, manager.conversation)
		.environment(\.attachmentFetcher, manager.attachments)
		.environment(\.selectedMsg, manager.layoutManager.selectedMsg)
		.environment(\.sharedFocusState, SharedFocusState($focusState))
		.environment(\.sharedNamespace, SharedNamespace(namespace))
		.environment(\.msgCellActions, MsgCellAction(action: handleMsgCellInteraction))

	}
}

private extension ConversationScene {
	func handleMsgCellInteraction(action: MsgCellAction.ActionType) {
		switch action {
		case .onTapMsg(let string):
			manager.setSelectedMsg(string)
		case .onMarkMsg(_):
			break
		case .onTapAvatar(let string):
			guard let vieModel = manager.models.element(withID: string) else { return }
			let msg = vieModel.msg
			let senderID = msg.senderID
			if let contact = coordinator.container.contactsRepository.contact(for: senderID) {
				coordinator.router.pushToNav(.contactDetails(contact))
			}
		case .onFocusMsgBubble(let frame):
			manager.presentation.updateFocusedFrame(frame)
		case .onUploadedAttachments(_):
			break
		case .onReact(let message, let reactionType):
			Task {
				try? await Socket
					.send(
						.reaction(
							reaction: .init(
								reaction: .init(
									rawValue: reactionType.rawValue,
									senderID: message.senderID,
									date: .now
								),
								msgID: message.uid,
								conID: manager.conversation.uid
							)
						),
						conversation: manager.conversation
					)
			}
		}
	}
}
