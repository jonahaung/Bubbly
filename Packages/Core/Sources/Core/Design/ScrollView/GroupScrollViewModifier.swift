//
//  GroupScrollViewModifier.swift
//  Core
//
//  Created by Aung Ko Min on 16/4/26.
//

import SwiftUI

// MARK: - GroupScrollViewModifier

private struct GroupScrollViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .contentMargins(.horizontal, Padding.md, for: .scrollContent)
            .applyBackground()
    }
}

public extension View {
    func groupScrollViewStyle() -> some View {
        modifier(GroupScrollViewModifier())
    }
}
