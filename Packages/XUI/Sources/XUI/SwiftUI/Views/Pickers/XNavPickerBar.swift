//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import SwiftUI

public struct XNavPickerBar<T: XPickable>: View {

	private let title: String
	private let items: [T]
	@Binding private var selection: T

	public init(_ title: String = "Picker", _ items: [T], _ selection: Binding<T>) {
		self.title = title
		self.items = items
		_selection = selection
	}

	public var body: some View {
		NavigationLink {
			XPickerView(
				title: title,
				items: items,
				selection: $selection
			)
		} label: {
			LabeledContent(title) {
				Text(selection.title)
			}
		}
	}
}

public struct XPickerView<T: XPickable>: View {
	let title: String
	let items: [T]
	@Binding var selection: T
	@State private var searchText = ""
	@Environment(\.dismiss) private var dismiss
	@State private var isPresented = false

	private var currentItems: [T] {
		if searchText.isEmpty {
			return items
		}
		let needle = searchText.lowercased()
		return items.filter { $0.title.lowercased().contains(needle) }
	}

	public init(
		title: String,
		items: [T],
		selection: Binding<T>
	) {
		self.title = title
		self.items = items
		_selection = selection
	}

	public var body: some View {
		Form {
			Section {
				ForEach(currentItems) { item in
					PickerRow.init(
						item: item,
						isSelected: item.title == selection.title,
						badge: item.badge
					) {
						update(item)
					} onFinished: {
						dismiss()
					}
					.id(item.id)
				}
				if currentItems.isEmpty {
					ContentUnavailableView.search
				}
			}
		}
		.toolbar {
			ToolbarItem(placement: .primaryAction) {
				AsyncButton {
					await MainActor.run {
						isPresented = true
					}
				} label: {
					SystemImage(.magnifyingglass)
				}
			}
		}
		.navigationBarTitle(title)
		.navigationSubtitle("Pick one from the list")
		.toolbarTitleDisplayMode(.inlineLarge)
		.searchable(
			text: $searchText,
			isPresented: $isPresented,
			placement: .navigationBarDrawer(displayMode: .automatic),
			prompt: "Search \(title)"
		)
		.sensoryFeedback(.selection, trigger: selection)
	}

	private func update(_ item: T) {
		if selection.title == item.title {
			selection = T.empty
			return
		}
		selection = item
	}
}

private struct PickerRow<T: XPickable>: View {
	let item: T
	let isSelected: Bool
	let badge: RenderNode?
	let action: () -> Void
	let onFinished: () -> Void

	var body: some View {
		CustomButton(action: action) {
			Label {
				LabeledContent {
					SystemImage(.circle)
						.symbolVariant(isSelected ? .fill : .none)
						.foregroundStyle(isSelected ? .secondary : .quinary)
				} label: {
					Text(item.title)
				}
			} icon: {
				if let badge {
					badge.eraseToNode()
				}
			}
			.background(Color.systemBackground.opacity(0.001))
		} onFinished: {
			onFinished()
		}
	}
}
