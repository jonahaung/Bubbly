
import Core
import Database
import Services
import SwiftUI
import XUI

public struct ConversationScene: View {

	// MARK: Lifecycle

	public init(
		_ prefetchedData: ConversationInitializer.PrefetchedData,
		coordinator: AppCoordinator,
	) {
		_manager = .init(wrappedValue: .init(prefetchedData))
		self.coordinator = coordinator
	}

	// MARK: Public

	public var body: some View {
		ZStack(alignment: .bottom) {
			BackgroundView()
			ChatScrollView()
			SeenStatusOverlay(coordinator: coordinator)
			ConversationSceneOverlayBar()

			if let frame = manager.presentation.state.overlayItem,
			   let overlayViewModel = manager.models.element(withID: frame.id)
			{
				OverlayMenuBar(item: frame)
					.environment(overlayViewModel)
			}
		}
		.tint(.link.mix(with: .primary, by: 0.2))
		.font(.system(size: UIFont.preferredFont(forTextStyle: .body).pointSize).leading(.tight))
		.environment(\.conversation, manager.state.conversation)
		.environment(\.conversationTheme, manager.state.theme)
		.environment(\.attachmentFetcher, manager.attachmentFetcher)
		.environment(\.sharedFocusState, SharedFocusState($focusState))
		.environment(\.sharedNamespace, SharedNamespace(namespace))
		.environment(\.msgCellActions, MsgCellAction(action: handleMsgCellInteraction))
		.environment(manager)
		.onAppear(perform: manager.onViewAppear)
		.onDisappear(perform: manager.onViewDisappear)
		.equatable(by: manager.state.reloadID)
	}

	// MARK: Internal

	let coordinator: AppCoordinator

	// MARK: Private

	@FocusState private var focusState: String?
	@Namespace private var namespace

	@LazyState private var manager: ChatManager

}

fileprivate extension ConversationScene {
	func handleMsgCellInteraction(action: MsgCellAction.ActionType) {
		switch action {
		case .onTapMsg(let string):
			manager.setSelectedMsg(string)
		case .onMarkMsg:
			break
		case .onTapAvatar(let string):
			guard let vieModel = manager.models.element(withID: string) else {
				return
			}
			let msg = vieModel.msg
			let senderID = msg.senderID
			if let contact = coordinator.container.contactsRepository.contact(for: senderID) {
				Router.shared.pushToNav(.contactDetails(contact))
			}
		case .onFocusMsgBubble(let frame):
			manager.presentation.send(.overlayItem(frame))
			manager.layoutIfNeeded()
		case .onUploadedAttachments:
			break
		case .onReact(let message, let reactionType):
			Task {
				try? await Socket
					.send(
						.reaction(
							reaction: .init(
								reaction: .init(
									rawValue: reactionType.rawValue,
									senderID: currentUserID ?? "",
									date: .now,
								),
								msgID: message.uid,
								conID: manager.state.conversation.uid,
							),
						),
						conversation: manager.state.conversation,
					)
			}
		}
	}
}
