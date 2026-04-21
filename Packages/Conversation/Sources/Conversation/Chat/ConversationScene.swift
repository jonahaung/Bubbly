// © 2026 Aung Ko Min

import Core
import Database
import Services
import SwiftUI
import XUI

public struct ConversationScene: View {
    
    public init(
        coordinator: AppCoordinator,
        prefretchData: ConversationInitializer.PrefetchedData,
    ) {
        _viewModel = .init(
            wrappedValue: .init(
                prefretchData,
                contactsRepository: coordinator.container.contactsRepository,
                currentUserRepository: coordinator.container
                    .currentUserRepository,
                router: coordinator.router,
            )
        )
    }

    // MARK: Public

    public var body: some View {
        ZStack(alignment: .bottomTrailing) {
            BackgroundView(
                imageName: viewModel.state.properties.theme.background.imageName
            )
            ConversationScrollView()
                .layoutPriority(1)
            ConversationSceneOverlayBar()
            SeenStatusOverlay()
            if let frame = viewModel.presentation.state.overlayItem,
                let overlayViewModel = viewModel.models.element(
                    withID: frame.id
                )
            {
                OverlayMenu(item: frame)
                    .id(frame.id)
                    .environment(overlayViewModel)
            }
        }
        .environment(\.conversation, viewModel.state.conversation)
        .environment(\.conversationTheme, viewModel.state.theme)
        .environment(\.attachmentFetcher, viewModel.attachmentFetcher)
        .environment(\.sharedFocusState, SharedFocusState($focusState))
        .environment(\.sharedNamespace, SharedNamespace(namespace))
        .environment(
            \.msgCellActions,
            MsgCellAction(action: { viewModel.send(.cellAction($0)) }),
        )
        .environment(viewModel)
        .environment(composer)
        .onAppear(perform: viewModel.onViewAppear)
        .onDisappear(perform: viewModel.onViewDisappear)
    }
    @FocusState private var focusState: String?
    @Namespace private var namespace

    @LazyState private var viewModel: ChatManager
    @LazyState private var composer: ChatComposer = .init()
}
