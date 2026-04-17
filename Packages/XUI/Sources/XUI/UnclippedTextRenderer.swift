//
//  UnclippedTextRenderer.swift
//  XUI
//
//  Created by Aung Ko Min on 18/4/26.
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

extension View {
    public nonisolated func unclippedTextRenderer() -> some View {
        textRenderer(UnclippedTextRenderer())
    }
}
