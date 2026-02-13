import SwiftUI

@available(iOS 18.0, *)
public struct PagerTabView<Item, Content, TabButton>: View
	where Item: Sendable & Equatable & Hashable & Identifiable, Content: View, TabButton: View
{
	private let items: [Item]
	private let content: (Item) -> Content
	private let tab: (Item, Bool) -> TabButton
	@Binding private var selection: Item

	public init(items: [Item],
	            selection: Binding<Item>,
	            content: @escaping (Item) -> Content,
	            tab: @escaping (Item, Bool) -> TabButton)
	{
		self.items = items
		self.content = content
		_selection = selection
		self.tab = tab
	}

	public var body: some View {
		VStack(spacing: 0) {
			PagerTabMenuBar(items: items, selection: $selection) { item, isSelected in
				tab(item, isSelected)
			}
			Divider().foregroundStyle(.quinary)
			//            PagerScrollView(items: items, selection: $selection, content: content)
		}
	}
}
