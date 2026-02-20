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
		ZStack(alignment: .center) {
			ConversationSceneBackground(color: manager.conversation.theme.background.color)
				.backgroundExtensionEffect()

			if let frame = manager.scrollController.inputAccessoryFrame, frame.minX >= 0 {
				MsgsScrollView(accessoryFrame: frame, manager: manager)
					.safeAreaPadding(.bottom, frame.height)
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
						let frame = geometry.globalFrame
						let insets = geometry.safeAreaInsets
						let uiInsets = UIEdgeInsets(top: 0, left: insets.leading, bottom: 0, right: insets.trailing)
						return frame.inset(by: uiInsets)
					} action: { oldValue, newValue in
						guard oldValue != newValue else { return }
						manager.send(.onBottomBarFrameChage(oldValue, newValue))
					}
			}

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
//		Task { @MainActor in
//
//			do {
//				switch action {
//				case let .onTapMsg(uid):
//					await viewModel.send(.tapMessage(uid))
//				case let .onTapAvatar(id):
//					await viewModel.send(.tapAvatar(id))
//				case let .onMarkMsg(data):
//					await viewModel.send(.markMessage(data))
//				case let .onFocusMsgBubble(item):
//					await viewModel.send(.focusMsgBubble(item))
//				case let .onUploadedAttachments(msg):
//					await viewModel.send(.uploadedAttachments(msg))
//				case let .onReact(msg, reaction):
//					await viewModel.send(.react(msg, reaction))
//				}
//			} catch {
//				// Handle message interaction errors gracefully
//				print("Error handling message interaction: \(error)")
//			}
//		}
	}
}
