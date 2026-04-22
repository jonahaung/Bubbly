//  HighlightTextRenderer.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import SwiftUI

/// A custom TextRenderer that draws a background highlight
/// behind text runs marked with `HighlightAttribute`
public struct HighlightTextRenderer: TextRenderer {

    private let style: any ShapeStyle

    public init(style: any ShapeStyle = .yellow) {
        self.style = style
    }

    // MARK: - TextRenderer

    public func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        for run in layout.flattenedRuns {
            let copy = context

            if run[HighlightAttribute.self] != nil {
                let rect = run.typographicBounds.rect

                let shape = Rectangle()
                    .path(in: rect)

                copy.fill(shape, with: .style(style))
                copy.draw(run)
            } else {
                copy.draw(run)
            }
        }
    }
}
