//
//  InboxScene.swift
//  Bubbly
//
//  Created by Aung Ko Min on 28/4/25.
//

import Database
import ImageLoader
import Services
import SwiftData
import SwiftUI
import XUI

struct InboxScene: View {
    @Environment(Router.self) private var router
    @Environment(\.currentUser) private var currentUser

    @LazyState private var viewModel = InboxViewModel()

    var body: some View {
        List {
            ForEach(viewModel.items, id: \.msg) { item in
                InboxCell(item: item)
            }
            .onDelete { _ in
                //				Task {
                //					await withThrowingTaskGroup(of: Void.self) { group in
                //						for index in indexSet {
                //							group.addTask {
                //								if let item = await viewModel.items[safe: index]?.conversation {
                //									try await Store.shared.conversationStore
                //										.delete(uid: item.uid)
                //								}
                //							}
                //						}
                //					}
                //					await viewModel.fetch()
                //				}
            }
        }
        .transaction(value: viewModel.items.first?.msg) { transactions in
            transactions.disablesAnimations = false
            transactions.animation = .snappy
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Ask AI") {
					ConversationInitializer.start(conversation: Conversation(.system(AI.contact), properties: .init(uid: AI.contact.uid)))
                }
            }
        }
        .task {
            await viewModel.task(currentUser: currentUser)
        }
        .refreshable {
            await viewModel.task(currentUser: currentUser)
        }
        .onDisappear {
            viewModel.ondisappear()
        }
    }
}
