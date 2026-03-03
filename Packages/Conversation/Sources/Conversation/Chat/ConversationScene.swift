//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Core
import Database
import Services
import SwiftUI
import XUI

enum Orientation: Hashable {
    case portrait
    case landscape
}

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
                .layoutPriority(1)
            if manager.layoutManager.boundsWidth > 0 {
                MsgsScrollView(manager: manager)
                    .safeAreaPadding(.bottom, ChatLayoutConstants.bottomBarHeight)
                    .task {
                        manager.send(.onVisibilityChange(visibility: .visible))
                    }
                    .layoutPriority(5)
            }
            VStack(alignment: .center, spacing: 0) {
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
                        if oldValue.maxX != newValue.maxX {
                            let isInitial = manager.layoutManager.boundsWidth == 0
                            withTransaction(.scrollView(preservePosition: true)) {
                                manager.layoutManager.updateBoundsWidth(newValue.width)
                                if !isInitial {
                                    manager.layoutIfNeeded()
                                }
                            }
                        } else {
                            manager.send(.onBottomBarFrameChage(oldValue, newValue))
                        }
                    }
            }
            .flexible(.horizontal)
            .layoutPriority(10)

            if let frame = manager.presentation.state.overlayItem,
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

        .environment(manager)
        .environment(composer)
        .toolbarVisibility(.hidden, for: .navigationBar)
        .environment(\.conversationTheme, manager.state.theme)
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
        case let .onTapMsg(string):
            manager.setSelectedMsg(string)
        case .onMarkMsg:
            break
        case let .onTapAvatar(string):
            guard let vieModel = manager.models.element(withID: string) else { return }
            let msg = vieModel.msg
            let senderID = msg.senderID
            if let contact = coordinator.container.contactsRepository.contact(for: senderID) {
                coordinator.router.pushToNav(.contactDetails(contact))
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
