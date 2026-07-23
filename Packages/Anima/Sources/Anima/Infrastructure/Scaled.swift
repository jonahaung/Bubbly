//  Scaled.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import SwiftUI

/// Scales the domain of a View Modifier to avoid snapping when animating with a spring animation.
@MainActor
struct Scaled<V: ViewModifier & Animatable>: @MainActor ViewModifier, @MainActor Animatable {
    var animatableData: V.AnimatableData {
        get {
            var v = base.animatableData
            v.scale(by: 64)
            return v
        }
        set {
            var v = newValue
            v.scale(by: 1 / 64)
            base.animatableData = v
        }
    }

    var base: V

    init(_ base: V) {
        self.base = base
    }

    func body(content: Content) -> some View {
        content.modifier(base.animation(nil))
    }
}

extension Scaled: @MainActor ProgressableAnimation where V.AnimatableData == CGFloat {}
