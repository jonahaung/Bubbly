//
//  InboxScene.swift
//  Bubbly
//
//  Created by Aung Ko Min on 28/4/25.
//

import SwiftUI
import XUI
import SwiftData
import ImageLoader
import MsgRoomMain
import Services
import Database

struct InboxScene: View {

    @Environment(Router.self) private var router

    @State private var viewModel = InboxViewModel()

    var body: some View {
        List {
			ForEach(viewModel.items) { item in
				InboxCell(item: item)
					.equatable(by: item.msg)
            }
			.onDelete { indexSet in
				Task {
					await withThrowingTaskGroup(of: Void.self) { group in
						for index in indexSet {
							group.addTask {
								if let item = await viewModel.items[safe: index]?.conversation {
									try await Store.shared.conversationStore
										.delete(uid: item.uid)
								}
							}
						}
					}
					await viewModel.fetch()
				}
			}
			ForEach(viewModel.conversations, id: \.uid) { item in
				Text(item.name)
			}.onDelete { indexSet in
				Task {
					await withThrowingTaskGroup(of: Void.self) { group in
						for index in indexSet {
							group.addTask {
								if let item = await viewModel.conversations[safe: index] {
									try await Store.shared.conversationStore
										.delete(uid: item.uid)
								}
							}
						}
					}
					await viewModel.fetch()
				}
			}
        }
		.animation(.bouncy, value: viewModel.items)
        .navigationTitle("MsgRoom")
        .task {
            await viewModel.fetch()
        }
    }
}
