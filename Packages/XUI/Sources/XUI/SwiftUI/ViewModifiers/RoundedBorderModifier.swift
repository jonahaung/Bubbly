//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import SwiftUI

struct RoundedBorderModifier: ViewModifier {
    let cornerRadius: CGFloat
    let color: Color

    func body(content: Content) -> some View {
        content
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(color, lineWidth: 1)
            )
    }
}

public extension View {
    func roundWithBorder(
        color: Color = Color.gray.opacity(0.4),
        cornerRadius: CGFloat = 16
    ) -> some View {
        modifier(RoundedBorderModifier(cornerRadius: cornerRadius, color: color))
    }
}
