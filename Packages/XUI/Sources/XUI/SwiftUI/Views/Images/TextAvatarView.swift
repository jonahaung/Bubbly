//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import SwiftUI

public struct TextAvatarView: View {
    private let text: String
    private let color: Color
    @Environment(\.colorScheme) private var colorScheme
    public init(text: String) {
        self.text = text.words().compactMap(\.first).prefix(2).map { String($0).uppercased() }
            .joined()
        color = text.color
    }

    public init(fullText: String) {
        text = fullText
        color = text.color
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack {
                Circle().fill(color.gradient)
                    .brightness(colorScheme == .dark ? -0.2 : -0.03)
                Text(text)
                    .font(
                        .system(size: geo.size.height * 0.5, weight: .medium)
                            .width(.condensed)
                    )
					.foregroundStyle(Color(.tertiarySystemBackground))
                    .unclippedTextRenderer()
            }
			.aspectRatio(1, contentMode: .fit)
        }
        .equatable(by: text)
    }
}
