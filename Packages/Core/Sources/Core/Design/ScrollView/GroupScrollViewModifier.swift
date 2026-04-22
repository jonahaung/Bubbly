//  GroupScrollViewModifier.swift
//
//  Copyright © 2026 Aung Ko Min.
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
