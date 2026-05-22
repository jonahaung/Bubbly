//  QuakeRenderer.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import SwiftUI

public struct QuakeRenderer: TextRenderer {
    var moveAmount: Double
    public var animatableData: Double {
        get { moveAmount }
        set { moveAmount = newValue }
    }

    public init(moveAmount: Double) {
        self.moveAmount = moveAmount
    }

    public func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        for line in layout {
            for run in line {
                for glyph in run {
                    var copy = context
                    if -moveAmount <= moveAmount {
                        let yOffset = Double.random(in: -moveAmount ... moveAmount)
                        copy.translateBy(x: yOffset, y: 0)
                    }
                    copy.draw(glyph, options: .disablesSubpixelQuantization)
                }
            }
        }
    }
}

public struct ColorfulRender: TextRenderer {
    public init() {}
    public func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        for (index, slice) in layout.flattenedRunSlices.enumerated() {
            let degree = Angle.degrees(360 / Double(index + 1))
            var copy = context
            copy.addFilter(.hueRotation(degree))
            copy.draw(slice)
        }
    }
}

extension Text.Layout {
    var flattenedRuns: some RandomAccessCollection<Text.Layout.Run> {
        flatMap { line in
            line
        }
    }
}

extension Text.Layout {
    var flattenedRunSlices: some RandomAccessCollection<Text.Layout.RunSlice> {
        flattenedRuns.flatMap(\.self)
    }
}
