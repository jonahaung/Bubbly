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
	@Environment(\.currentUser) private var currentUser

	@LazyState private var viewModel = InboxViewModel()

	var body: some View {
		List {
			ForEach(viewModel.items, id: \.msg) { item in
				InboxCell(item: item)
			}
			.onDelete { _ in
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
		.navigationTitle("pencil.line")
		.toolbar {
			ToolbarItem(placement: .primaryAction) {
				Button {} label: {
					SystemImage(.bellBadge)
				}
			}.sharedBackgroundVisibility(.hidden)
		}
	}
}
