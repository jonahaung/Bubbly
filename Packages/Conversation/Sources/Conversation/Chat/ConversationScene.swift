import Core
import Database
import Services
import SwiftUI
import XUI

public struct ConversationScene: View {

	@Environment(\.dismiss) private var dismiss
	@FocusState private var focusState: String?
	@Namespace private var namespace
	@LazyState private var manager: ChatViewManager
	@LazyState private var composer: ChatComposer

	public init(_ prefetchedData: ConversationInitializer.PrefetchedData) {
		_manager = .init(wrappedValue: .init(prefetchedData))
		_composer = .init(wrappedValue: .init(id: prefetchedData.conversation.uid))
	}

	public var body: some View {
		ZStack(alignment: .bottom) {
			ConversationSceneBackground(color: manager.conversation.theme.background.color)
				.backgroundExtensionEffect()

			if manager.layoutManager.config.boundsWidth > 0 {
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
			}.layoutPriority(1)

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
		.environment(\.backgroundColor, manager.conversation.theme.background.color)
		.environment(\.conversationTheme, .init(manager.conversation))
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
		case .onMarkMsg(let message):
			break
		case .onTapAvatar(let string):
			
			Task {
				if let contact = try? await ContactRepo.getOrCreate(uid: string, refetch: false) {
					Router.shared.pushToNav(.contactDetails(contact))
				}
			}
		case .onFocusMsgBubble(let frame):
			manager.presentation.updateFocusedFrame(frame)
		case .onUploadedAttachments(let message):
			break
		case .onReact(let message, let reactionType):
			break
		}
	}
}
