//  UnclippedTextRenderer.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import SwiftUI

struct UnclippedTextRenderer: TextRenderer {
    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        for line in layout {
            context.draw(line)
        }
    }

    func sizeThatFits(proposal: ProposedViewSize, text: TextProxy) -> CGSize {
        text.sizeThatFits(proposal)
    }
}

public extension View {
    nonisolated func unclippedTextRenderer() -> some View {
        textRenderer(UnclippedTextRenderer())
    }
}
