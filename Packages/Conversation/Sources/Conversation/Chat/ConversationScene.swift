// © 2026 Aung Ko Min

import Core
import Database
import Services
import SwiftUI
import XUI

public struct ConversationScene: View {
    // MARK: Lifecycle

    public init(
        coordinator: AppCoordinator,
        prefretchData: ConversationInitializer.PrefetchedData,
    )
    {
        _viewModel = .init(wrappedValue: .init(
            prefretchData,
            contactsRepository: coordinator.container.contactsRepository,
            currentUserRepository: coordinator.container.currentUserRepository,
            router: coordinator.router,
        ))
    }

    // MARK: Public

    public var body: some View {
        ZStack(alignment: .bottom) {
            BackgroundView()
            ConversationScrollView()
            SeenStatusOverlay()
            ConversationSceneOverlayBar()

            if let frame = viewModel.presentation.state.overlayItem,
               let overlayViewModel = viewModel.models.element(withID: frame.id)
            {
                OverlayMenu(item: frame)
                    .environment(overlayViewModel)
            }
        }
        .environment(\.conversation, viewModel.state.conversation)
        .environment(\.conversationTheme, viewModel.state.theme)
        .environment(\.attachmentFetcher, viewModel.attachmentFetcher)
        .environment(\.sharedFocusState, SharedFocusState($focusState))
        .environment(\.sharedNamespace, SharedNamespace(namespace))
        .environment(viewModel)
        .environment(
            \.msgCellActions,
            MsgCellAction(action: viewModel.handleMsgCellInteraction(action:)),
        )
        .onAppear(perform: viewModel.onViewAppear)
        .onDisappear(perform: viewModel.onViewDisappear)
        .equatable(by: viewModel.state.reloadID)
    }

    // MARK: Private

    @FocusState private var focusState: String?
    @Namespace private var namespace
    @LazyState private var viewModel: ChatManager
}
