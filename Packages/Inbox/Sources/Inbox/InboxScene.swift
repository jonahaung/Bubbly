// © 2026 Aung Ko Min

import Core
import Database
import ImageLoader
import Services
import SwiftData
import SwiftUI
import XUI

public struct InboxScene: View {
    private let coordinator: AppCoordinator
    @Environment(\.openURL) private var openURL
    @Environment(\.currentUser) private var currentUser
    @State private var viewModel: InboxViewModel

    public init(coordinator: AppCoordinator) {
        self.coordinator = coordinator
        _viewModel = .init(wrappedValue: .init())
    }

    public var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading) {
                ScrollSection(data: viewModel.state.items) { item in
                    InboxCell(item: item) {
                        if let url = coordinator.deeplinkCoordinator
                            .url(for: .conversation(conID: $0.conversation.uid))
                        {
                            openURL(url)
                        }
                    }
                }
            }
        }
        .groupScrollViewStyle()
        .task {
            await viewModel.send(.appear(currentUser))
        }
        .refreshable {
            await viewModel.send(.refresh)
        }
        .onDisappear {
            Task { await viewModel.send(.disappear) }
        }
        .navigationTitle(TabPath.inbox.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {} label: {
                    AppIcon(30)
                }
            }.sharedBackgroundVisibility(.hidden)
        }
    }
}
