//  Flicker.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import SwiftUI

@MainActor
public extension AnyTransition.MovingParts {
    /// A transition that toggles the visibility of the view multiple times
    /// before settling.
    static var flicker: AnyTransition {
        flicker(count: 1)
    }

    /// A transition that toggles the visibility of the view multiple times
    /// before settling.
    ///
    /// - Parameter count: The number of times the visibility is toggled.
    static func flicker(count: Int) -> AnyTransition {
        let count = clamp(1, count, .max)

        return .modifier(
            active: Flicker(count: count, animatableData: 0),
            identity: Flicker(count: count, animatableData: 1)
        )
    }
}

struct Flicker: ViewModifier, ProgressableAnimation, AnimatableModifier, Hashable {
    var count: Int

    var animatableData: CGFloat

    private var isVisible: Bool {
        (progress * CGFloat(count)).remainder(dividingBy: 1) >= 0
    }

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .animation(nil, value: isVisible)
    }
}
