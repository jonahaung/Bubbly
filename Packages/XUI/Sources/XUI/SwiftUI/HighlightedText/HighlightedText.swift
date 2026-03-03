//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

public struct HighlightedText: View {
    private let text: String
    private let highlightedText: String?
    private let shapeStyle: (any ShapeStyle)?

    public init(
        text: String,
        highlightedText: String? = nil,
        shapeStyle: (any ShapeStyle)? = nil
    ) {
        self.text = text
        self.highlightedText = highlightedText
        self.shapeStyle = shapeStyle
    }

    public var body: some View {
        if let highlightedText, !highlightedText.isWhitespace {
            let components = highlightedComponents(from: highlightedText)
            let composedText: Text = components.reduce(Text("")) { partial, component in
                Text("\(partial)\(component.text)")
            }

            composedText.textRenderer(
                HighlightTextRenderer(style: shapeStyle ?? .yellow)
            )
        } else {
            Text(text)
        }
    }

    private func highlightedComponents(from highlight: String) -> [HighlightedTextComponent] {
        let highlighted = text
            .ranges(of: highlight, options: .caseInsensitive)
            .map {
                HighlightedTextComponent(
                    text: Text(.init(text[$0]))
                        .customAttribute(HighlightAttribute()),
                    range: $0
                )
            }

        let remaining = text
            .remainingRanges(from: highlighted.map(\.range))
            .map {
                HighlightedTextComponent(
                    text: Text(.init(text[$0])),
                    range: $0
                )
            }

        return (highlighted + remaining)
            .sorted { $0.range.lowerBound < $1.range.lowerBound }
    }
}

private struct HighlightedTextComponent {
    let text: Text
    let range: Range<String.Index>
}
