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
    @State private var sharedFocusState: SharedFocusState<ConversationFocusState>?
    @LazilyState private var viewModel: ChatManager
    @LazilyState private var composer: ChatComposer
    @Environment(\.colorScheme) private var colorScheme

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
        ZStack {
            BackgroundView(imageName: viewModel.state.properties.theme.background.imageName)
            SeenStatusOverlay()
                .ignoresSafeArea(.all, edges: .top)
            ConversationScrollView(manager: viewModel)
                .ignoresSafeArea(.all, edges: .top)
            ConversationSceneOverlayBar()
        }
        .environment(\.conversation, viewModel.state.conversation)
        .environment(\.conversationTheme, viewModel.state.theme)
        .environment(\.attachmentFetcher, viewModel.attachmentFetcher)
        .environment(\.seenMembers, viewModel.state.properties.seenMembers)
        .environment(\.sharedFocusState, sharedFocusState)
        .environment(\.members, viewModel.members)
        .environment(\.sharedNamespace, namespace)
        .environment(\.msgCellActions, .init(action: { viewModel.send(.cellAction($0)) }))
        .environment(viewModel)
        .environment(composer)
        .task {
            if sharedFocusState == nil {
                let sharedFocusState = SharedFocusState($focusState)
                self.sharedFocusState = sharedFocusState
                viewModel.focusState = sharedFocusState
            }
            await viewModel.onViewAppear()
        }
    }
}
