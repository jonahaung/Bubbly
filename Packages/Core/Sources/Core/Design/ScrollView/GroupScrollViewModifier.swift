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
            .background(Color.background)
    }
}

public extension View {
    func groupScrollViewStyle() -> some View {
        modifier(GroupScrollViewModifier())
    }
}
