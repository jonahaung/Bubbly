//
//  ScrollViewList.swift
//  HomeForYou
//
//  Created by Aung Ko Min on 11/6/24.
//

import SwiftUI

public struct ScrollViewList<Content: View>: View {
    private let content: Content

    @State private var innerPadding: CGFloat
    @State private var outerPadding: CGFloat

    public init(innerPadding: CGFloat = 10.scaled, outerPadding: CGFloat = 10.scaled, @ViewBuilder content: () -> Content) {
        self.innerPadding = innerPadding
        self.outerPadding = outerPadding
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading) {
            _VariadicView.Tree(
                VInsetGroupListSection()
            ) {
                content
            }
        }
        .padding(innerPadding)
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: innerPadding < 10 ? 8 : 12))
        .padding(outerPadding)
        .flexible(.horizontal)
    }
}

public extension ScrollViewList {
    func outerPadding(_ value: CGFloat) -> ScrollViewList {
        let result = self
        result.outerPadding = value
        return result
    }

    func innerPadding(_ value: CGFloat) -> ScrollViewList {
        let result = self
        result.innerPadding = value
        return result
    }
}

private struct VInsetGroupListSection: _VariadicView.MultiViewRoot {
    func body(children: _VariadicView.Children) -> some View {
        ForEach(children) { child in
            VInsetGroupListCell {
                child
            }
        }
    }
}

private struct VInsetGroupListCell<Content: View>: View {
    private let content: Content
    init(@ViewBuilder _ content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
