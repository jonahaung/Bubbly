//  ConversationScene.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Core
import Database
import Services
import SwiftUI
import XUI

public struct ConversationScene: View {
    
    @FocusState private var focusState: ConversationFocusState?
    @Namespace private var namespace

    @LazyState private var viewModel: ChatManager
    @LazyState private var composer: ChatComposer
    
    public init(
        coordinator: AppCoordinator,
        prefretchData: ConversationInitializedData
    ) {
        _viewModel = .init(
            wrappedValue: .init(
                prefretchData,
                currentUserRepository: coordinator.container
                    .currentUserRepository,
                router: coordinator.router
            )
        )
        _composer = .init(wrappedValue: .init())
    }

    public var body: some View {
        ZStack(alignment: .bottomTrailing) {
            BackgroundView(imageName: viewModel.state.properties.theme.background.imageName)
            SeenStatusOverlay()
            ConversationScrollView(manager: viewModel)
            ConversationSceneOverlayBar()
        }
        .ignoresSafeArea(.keyboard, edges: .top)
        .environment(\.conversation, viewModel.state.conversation)
        .environment(\.conversationTheme, viewModel.state.theme)
        .environment(\.attachmentFetcher, viewModel.attachmentFetcher)
        .environment(\.seenMembers, viewModel.state.properties.seenMembers)
        .environment(\.sharedFocusState, .init($focusState))
        .environment(\.members, viewModel.members)
        .environment(\.sharedNamespace, SharedNamespace(namespace))
        .environment(\.msgCellActions, .init(action: { viewModel.send(.cellAction($0)) }))
        .environment(viewModel)
        .environment(composer)
        .onAppear {
            viewModel.focusState = .init($focusState)
            viewModel.onViewAppear()
        }
    }
}
