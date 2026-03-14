//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Core
import Database
import Services
import SwiftUI
import XUI
public struct ConversationScene: View {

	let coordinator: AppCoordinator
    @LazyState private var manager: ChatViewManager
    @LazyState private var composer: ChatComposer
	@FocusState private var focusState: String?
	@Namespace private var namespace

    public init(_ prefetchedData: ConversationInitializer.PrefetchedData, coordinator: AppCoordinator) {
        _manager = .init(wrappedValue: .init(prefetchedData))
        _composer = .init(wrappedValue: .init(id: prefetchedData.conversation.uid))
        self.coordinator = coordinator
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            ConversationSceneBackground(color: manager.state.properties.theme.background.color)
                .layoutPriority(1)
				.equatable(by: manager.state.properties.theme.background)

			if let frame = manager.layout.bottomBarFrame {
				ChatScrollView(manager: manager)
					.safeAreaPadding(
						.init(
							top: ChatLayoutConstants.topBarHeight,
							leading: 8,
							bottom: ChatLayoutConstants.bottomBarHeight,
							trailing: 8
						)
					)
					.layoutPriority(5)
			}
            VStack(alignment: .center, spacing: 0) {
                ChatTitleBar()
                FloatingDateView()
                Spacer()
                ChatAccessoryBar()
				ComposeBar(composer: composer)
					.onGeometryChange(for: CGRect.self) { geometry in
						geometry.frame(in: .global)
					} action: { oldValue, newValue in
						manager.send(.onBottomBarFrameChage(oldValue, newValue))
					}
            }
            .layoutPriority(10)

            if let frame = manager.presentation.state.overlayItem,
               let overlayViewModel = manager.models.element(withID: frame.id) {
                ChatOverlayView(item: frame)
                    .font(.system(size: UIFont.preferredFont(forTextStyle: .body).pointSize))
                    .environment(overlayViewModel)
                    .environment(\.conversation, manager.conversation)
                    .environment(\.isVisible, true)
            }
        }
		.toolbarVisibility(.hidden, for: .tabBar)
		.toolbarVisibility(.hidden, for: .navigationBar)
        .environment(\.seenMembers, manager.state.properties.seenMembers)
        .environment(\.conversation, manager.conversation)
		.environment(\.conversationTheme, manager.state.theme)
        .environment(\.attachmentFetcher, manager.attachmentFetcher)
        .environment(\.sharedFocusState, SharedFocusState($focusState))
        .environment(\.sharedNamespace, SharedNamespace(namespace))
        .environment(\.msgCellActions, MsgCellAction(action: handleMsgCellInteraction))
		.environment(manager)
		.environment(composer)
		.task {
			await manager.onViewAppear()
		}
    }
}

private extension ConversationScene {
    func handleMsgCellInteraction(action: MsgCellAction.ActionType) {
        switch action {
        case let .onTapMsg(string):
            manager.setSelectedMsg(string)
        case .onMarkMsg:
            break
        case let .onTapAvatar(string):
            guard let vieModel = manager.models.element(withID: string) else { return }
            let msg = vieModel.msg
            let senderID = msg.senderID
            if let contact = coordinator.container.contactsRepository.contact(for: senderID) {
				Router.shared.pushToNav(.contactDetails(contact))
            }
        case let .onFocusMsgBubble(frame):
            manager.presentation.send(.overlayItem(frame))
        case .onUploadedAttachments:
            break
        case let .onReact(message, reactionType):
            Task {
                try? await Socket
                    .send(
                        .reaction(
                            reaction: .init(
                                reaction: .init(
                                    rawValue: reactionType.rawValue,
                                    senderID: currentUserId ?? "",
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
