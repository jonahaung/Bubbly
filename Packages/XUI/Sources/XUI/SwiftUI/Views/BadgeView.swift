//  BadgeView.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import SwiftUI

public extension View {
    func badgeView(_ content: some View) -> some View {
        overlay(
            content
                .alignmentGuide(.top) { $0.height / 2 }
                .alignmentGuide(.trailing) { $0.width / 2 }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        )
    }
}
