//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import SwiftUI

public struct TextAvatarView: View {
    private let text: String
    private let color: Color

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
                Text(text)
                    .font(
                        .system(size: geo.size.height * 0.5, weight: .medium)
                            .width(.condensed)
                    )
					.foregroundStyle(Color(.tertiarySystemBackground))
            }
			.aspectRatio(1, contentMode: .fit)
        }
        .equatable(by: text)
    }
}
