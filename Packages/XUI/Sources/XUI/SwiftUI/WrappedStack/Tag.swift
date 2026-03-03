//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

public struct Tag<Content: View>: View {
    private let content: () -> Content
    private let color: Color

    public init(color: Color = .secondary, @ViewBuilder content: @escaping () -> Content) {
        self.content = content
        self.color = color
    }

    public var body: some View {
        content()
            .font(
                .system(
                    size: UIFont.smallSystemFontSize,
                    weight: .medium,
                    design: .serif
                )
            )
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .frame(height: 25)
            .background {
                ContainerRelativeShape().strokeBorder(color, style: .init())
            }
    }
}
