//  Blur.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import SwiftUI

@MainActor
public extension AnyTransition.MovingParts {
    /// A transition from blurry to sharp on insertion, and from sharp to blurry
    /// on removal.
    static var blur: AnyTransition {
        .modifier(
            active: Blur(radius: 30),
            identity: Blur(radius: 0)
        )
    }

    /// A transition from blurry to sharp on insertion, and from sharp to blurry
    /// on removal.
    ///
    /// - Parameter radius: The radial size of the blur at the end of the transition.
    static func blur(radius: CGFloat) -> AnyTransition {
        .modifier(
            active: Blur(radius: radius),
            identity: Blur(radius: 0)
        )
    }
}

@MainActor
struct Blur: ViewModifier, @MainActor DebugProgressableAnimation, @MainActor AnimatableModifier, Hashable {
    var animatableData: CGFloat {
        get { radius }
        set { radius = newValue }
    }

    var radius: CGFloat

    func body(content: Content) -> some View {
        content
            .blur(radius: radius)
    }
}
