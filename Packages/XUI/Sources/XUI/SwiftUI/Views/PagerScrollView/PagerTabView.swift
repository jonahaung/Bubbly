//
//  PagerTabView.swift
//  UI
//
//  Created by Aung Ko Min on 13/12/24.
//

import SwiftUI

@available(iOS 18.0, *)
public struct PagerTabView<Page, Content, TabButton>: View where Page: Sendable & Equatable & Hashable & Identifiable, Content: View, TabButton: View {
    private let items: [Page]
    private let content: (Page) -> Content
    private let tab: (Page, Bool) -> TabButton
    @Binding private var selection: Page

    public init(items: [Page], selection: Binding<Page>, content: @escaping (Page) -> Content, tab: @escaping (Page, Bool) -> TabButton) {
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
            PagerScrollView(items: items, selection: $selection, content: content)
        }
    }
}
