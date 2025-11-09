//
//  StretchyHeaderModifier.swift
//  HomeForYou
//
//  Created by Aung Ko Min on 28/5/24.
//

import SwiftUI

private struct StretchyHeaderModifier<Header: View>: ViewModifier {
    @Binding var scrollViewOffset: CGFloat
    let height: CGFloat
    let multiplier: CGFloat
    let header: () -> Header

    init(
        _ scrollViewOffset: Binding<CGFloat>,
        height: CGFloat,
        multiplier: CGFloat = 0.5,
        @ViewBuilder header: @escaping () -> Header
    ) {
        _scrollViewOffset = scrollViewOffset
        self.height = height
        self.multiplier = multiplier
        self.header = header
    }

    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            header()
                .offset(y: scrollViewOffset > 0 ? -scrollViewOffset * multiplier : 0)
                .scaleEffect(scrollViewOffset < 0 ? (height - scrollViewOffset) / height : 1, anchor: .top)
                .animation(scrollViewOffset <= 10 ? .spring(duration: 0.5) : nil, value: scrollViewOffset)
            content
        }
    }
}

public extension View {
    func stretchyHeader(
        _ scrollViewOffset: Binding<CGFloat>,
        height: CGFloat,
        multiplier: CGFloat = 1,
        @ViewBuilder header: @escaping () -> some View
    ) -> some View {
        modifier(
            StretchyHeaderModifier(
                scrollViewOffset,
                height: height,
                multiplier: multiplier,
                header: header
            )
        )
    }
}
