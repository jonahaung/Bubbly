//
//  PagerScrollView.swift
//  HomeForYou
//
//  Created by Aung Ko Min on 26/4/23.
//

import Combine
import SwiftUI

public struct PagerScrollView<Item, Content>: View
where Item: Sendable & Equatable & Hashable & Identifiable, Content: View, Item.ID == String {
	
    private let items: [Item]
    private let content: (Item) -> Content
	@Binding private var selection: String
	@State private var position: String?

	public init(items: [Item], selection: Binding<Item.ID>, content: @escaping (Item) -> Content) {
        self.items = items
        self.content = content
        _selection = selection
    }

    public var body: some View {
		ScrollView(.horizontal, showsIndicators: false) {
			LazyHStack(alignment: .center, spacing: 0) {
				ForEach(items) { item in
					content(item)
						.containerRelativeFrame([.horizontal])
						.id(item.id)
				}
			}
			.scrollTargetLayout()
		}
		.scrollClipDisabled(true)
		.contentMargins(0)
		.scrollTargetBehavior(.paging)
		.scrollIndicators(.hidden)
		.scrollBounceBehavior(.basedOnSize)
		.scrollPosition(id: $position)
		.onAppear {
			position = selection
		}
		.onChange(of: position.str, initial: false) { oldValue, newValue in
			selection = newValue
		}
    }
}
