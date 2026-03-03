//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

@available(iOS 18.0, *)
public struct PagerTabMenuBar<Page, Content>: View
    where Page: Sendable & Equatable & Hashable & Identifiable, Content: View {
    let items: [Page]
    @Binding var selection: Page
    let content: ((Page, Bool)) -> Content

    public init(
        items: [Page],
        selection: Binding<Page>,
        content: @escaping ((Page, Bool)) -> Content
    ) {
        self.items = items
        _selection = selection
        self.content = content
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .bottom, spacing: 16) {
                ForEach(items) { item in
                    Button {
                        selection = item
                    } label: {
                        content((item, item == selection))
                            .padding(.vertical, 8)
                            .font(item == selection ? .title.weight(.semibold)
                                .width(.condensed) : .subheadline.weight(.medium).width(.condensed))
                    }
                    .id(item)
                }
            }
            .buttonStyle(.plain)
        }
        .scrollBounceBehavior(.basedOnSize)
        .defaultScrollAnchor(.center, for: .alignment)
        .scrollPosition(id: .init(get: { selection }, set: { _ in }))
        .animation(.spring, value: selection)
        .padding(8)
    }
}
