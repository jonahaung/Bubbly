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
				.background(
					viewModel.state.conversation.properties.theme.background.color
				)
				.foregroundStyle(
					AngularGradient(colors: Color.adaptableGrayColors, center: .topLeading)
				)
				.backgroundExtensionEffect()
				.equatable(by: 1)

			if let accessoryFrame = manager.scrollController.inputAccessoryFrame {
				GeometryReader { proxy in
					MsgsScrollView(proxy: proxy)
						.safeAreaPadding(.bottom, accessoryFrame.height)
						.task {
							await viewModel.send(.appear)
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
		.equatable(by: viewModel.state)
	}
}

private extension ConversationScene {
	func handleMsgCellInteraction(action: MsgCellAction.ActionType) {
		Task.detached(priority: .background) { [weak viewModel] in
			guard let viewModel else { return }
			switch action {
			case let .onTapMsg(uid):
				await viewModel.send(.tapMessage(uid))
			case let .onTapAvatar(id):
				await viewModel.send(.tapAvatar(id))
			case let .onMarkMsg(data):
				await viewModel.send(.markMessage(data))
			case let .onFocusMsgBubble(item):
				await viewModel.send(.focusMsgBubble(item))
			case let .onUploadedAttachments(msg):
				await viewModel.send(.uploadedAttachments(msg))
			case let .onReact(msg, reaction):
				await viewModel.send(.react(msg, reaction))
			}
		}
	}
}
