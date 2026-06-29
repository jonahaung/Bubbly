//  EarthquakeRenderer.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import SwiftUI

public struct EarthquakeAttribute: TextAttribute {
    public init() {}
}

public struct EarthquakeRenderer: TextRenderer {

    var moveAmount: Double
    var shouldBlur = false

    public var animatableData: Double {
        get { moveAmount }
        set { moveAmount = newValue }
    }

    public init(moveAmount: Double, shouldBlur: Bool = false) {
        self.moveAmount = moveAmount
        self.shouldBlur = shouldBlur
    }

    public func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        for line in layout {
            for run in line {
                for glyph in run {
                    let yOffset = Double.random(in: -moveAmount...moveAmount)
                    var copy = context

                    if shouldBlur {
                        copy.addFilter(.blur(radius: moveAmount / 4))
                    }

                    copy.translateBy(x: yOffset, y: yOffset)
                    copy.draw(glyph)
                }
            }
        }
    }
}
