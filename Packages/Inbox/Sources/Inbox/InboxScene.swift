import Database
import ImageLoader
import Services
import SwiftData
import SwiftUI
import XUI

public struct InboxScene: View {
	@Environment(\.currentUser) private var currentUser

	@State private var viewModel: InboxViewModel

	public init(viewModel: InboxViewModel) {
		self.viewModel = viewModel
	}

	public var body: some View {
		List {
			ForEach(viewModel.state.items, id: \.msg) { item in
				InboxCell(item: item)
			}
			.onDelete { _ in
			}
		}
		.task {
			await viewModel.send(.appear(currentUser))
		}
		.refreshable {
			await viewModel.send(.refresh)
		}
		.onDisappear {
			Task { await viewModel.send(.disappear) }
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
