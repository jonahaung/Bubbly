//  ScrollSection.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import SwiftUI

public struct ScrollSection<
    Data: RandomAccessCollection,
    Header: View,
    Footer: View,
    Cell: View
>: View where Data.Element: Identifiable {

    public init(
        data: Data,
        spacing: CGFloat = Spacing.md,
        showsDividers: Bool = true,
        @ViewBuilder cell: @escaping (Data.Element) -> Cell,
        @ViewBuilder header: () -> Header? = { EmptyView() },
        @ViewBuilder footer: () -> Footer? = { EmptyView() }
    ) {
        self.data = data
        self.spacing = spacing
        self.showsDividers = showsDividers
        self.header = header()
        self.footer = footer()
        self.cell = cell
    }

    // MARK: Public

    public var body: some View {
        if !data.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                if let header {
                    header
                        .padding(.horizontal, Padding.md)
                }
                VStack(alignment: .leading, spacing: spacing) {
                    ForEach(data) { item in
                        cell(item)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.container)
                            .id(item.id)
                    }
                    .if(
                        showsDividers,
                        { view in
                            view
                                .intersperse {
                                    Rectangle().fill(Color.background).frame(height: 1)
                                }
                        }
                    )
                }
                .padding(Padding.md)
                .background(Color.container, in: RoundedRectangle(cornerRadius: Radius.md))

                if let footer {
                    footer
                        .padding(.horizontal, Padding.md)
                }
            }
            .animation(.anticipateOvershoot, value: data.map(\.id))
            .geometryGroup()
        }
    }

    private let data: Data
    private let spacing: CGFloat
    private let showsDividers: Bool

    private let header: Header?
    private let footer: Footer?
    private let cell: (Data.Element) -> Cell
}
