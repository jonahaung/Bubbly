//  FilmExposure.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import SwiftUI

@MainActor
public extension AnyTransition.MovingParts {
    /// A transition from completely dark to fully visible on insertion, and
    /// from fully visible to completely dark on removal.
    static var filmExposure: AnyTransition {
        .modifier(
            active: ExposureFade(animatableData: 0),
            identity: ExposureFade(animatableData: 1)
        )
    }

    /// A transition from completely bright to fully visible on insertion, and
    /// from fully visible to completely bright on removal.
    static var snapshot: AnyTransition {
        .modifier(
            active: Snapshot(animatableData: 0),
            identity: Snapshot(animatableData: 1)
        )
    }
}

struct Snapshot: ViewModifier, ProgressableAnimation, AnimatableModifier, Hashable {
    var animatableData: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .saturation(0.5 + 0.5 * clamp(progress))
            .contrast(0.5 + 0.5 * clamp(progress))
            .brightness(0.85 * (1.0 - clamp(1 * progress)))
            .blur(radius: 5.0 * (1.0 - clamp(progress)), opaque: true)
            .animation(nil, value: progress)
    }
}

struct ExposureFade: ViewModifier, ProgressableAnimation, AnimatableModifier, Hashable {
    var animatableData: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .opacity(Double(1.0 - pow(2.0, -10.0 * progress)))
            .brightness(-1.0 * (1.0 - clamp(progress)))
            .animation(nil, value: progress)
    }
}
