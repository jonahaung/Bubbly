//  ScrollSection.swift
//
//  Copyright © 2026 Aung Ko Min. All rights reserved.
//

import SwiftUI

public struct ScrollSection<
    Data: RandomAccessCollection,
    Header: View,
    Footer: View,
    Cell: View
>: View where Data.Element: Identifiable {

    private let data: Data
    private let spacing: CGFloat
    private let showsDividers: Bool
    private let header: Header?
    private let footer: Footer?
    private let cell: (Data.Element) -> Cell

    public init(
        data: Data,
        spacing: CGFloat = Spacing.md,
        showsDividers: Bool = true,
        @ViewBuilder cell: @escaping (Data.Element) -> Cell,
        header: Header? = nil,
        footer: Footer? = nil,
    ) {
        self.data = data
        self.spacing = spacing
        self.showsDividers = showsDividers
        self.header = header
        self.footer = footer
        self.cell = cell
    }
    public init(
        data: Data,
        spacing: CGFloat = Spacing.md,
        showsDividers: Bool = true,
        @ViewBuilder cell: @escaping (Data.Element) -> Cell,
        @ViewBuilder header: () -> Header? = { EmptyView() },
        @ViewBuilder footer: () -> Footer? = { EmptyView() }
    ) {
        self.init(
            data: data,
            spacing: spacing,
            showsDividers: showsDividers,
            cell: cell, header: header(), footer: footer()
        )
    }

    public var body: some View {
        if !data.isEmpty {
            ScrollSectionContent(
                spacing: spacing,
                showsDividers: showsDividers,
                header: header,
                footer: footer
            ) {
                ForEach(data) { item in
                    cell(item)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .id(item.id)
                }
            }
        }
    }
}

public struct ScrollSectionContent<
    Header: View,
    Footer: View,
    Content: View
>: View {

    private let spacing: CGFloat
    private let showsDividers: Bool
    private let header: Header?
    private let footer: Footer?
    private let content: () -> Content

    public init(
        spacing: CGFloat = Spacing.md,
        showsDividers: Bool = true,
        header: Header? = nil,
        footer: Footer? = nil,
        content: @escaping () -> Content
    ) {
        self.spacing = spacing
        self.showsDividers = showsDividers
        self.header = header
        self.footer = footer
        self.content = content
    }

    public init(
        spacing: CGFloat = Spacing.md,
        showsDividers: Bool = true,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder header: () -> Header? = { EmptyView() },
        @ViewBuilder footer: () -> Footer? = { EmptyView() }
    ) {
        self.init(
            spacing: spacing,
            showsDividers: showsDividers,
            header: header(),
            footer: footer(),
            content: content
        )
    }

    public init(
        _ headerText: String,
        spacing: CGFloat = Spacing.md,
        showsDividers: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) where Header == Text, Footer == EmptyView {
        self.init(
            spacing: spacing,
            showsDividers: showsDividers,
            header: Text(headerText),
            content: content
        )
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if let header {
                header
                    .font(.headline)
                    .padding(.horizontal, Padding.md)
            }
            VStack(alignment: .leading, spacing: spacing) {
                content()
                    .if(showsDividers) { view in
                        view.intersperse {
                            Rectangle()
                                .fill(Color.background)
                                .frame(height: 1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(Padding.md)
            .background(
                Color.container,
                in: RoundedRectangle(cornerRadius: Radius.md)
            )
            if let footer {
                footer
                    .font(.footnote)
                    .lineHeight(.multiple(factor: 1.2))
                    .lineSpacing(0)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, Padding.md)
            }
        }
    }
}
