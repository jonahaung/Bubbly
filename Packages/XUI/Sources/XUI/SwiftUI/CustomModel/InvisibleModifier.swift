//  InvisibleModifier.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import SwiftUI

struct InvisibleModifier: @MainActor AnimatableModifier {
    var progress: CGFloat
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }
    func body(content: Content) -> some View {
        content
            .opacity(progress == 1.0 ? 1 : 0)
    }
}
public extension AnyTransition {
    @MainActor
    static func invisible() -> AnyTransition {
        AnyTransition.modifier(
            active: InvisibleModifier(progress: 0),
            identity: InvisibleModifier(progress: 1)
        )
    }
}
struct TextQuakeModifier: @MainActor AnimatableModifier {
    var progress: CGFloat
    let distance: CGFloat
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }
    func body(content: Content) -> some View {
        content
            .textRenderer(QuakeRenderer(moveAmount: progress == 1 ? 0 : (progress)*distance))
    }
}
public extension AnyTransition {
    @MainActor
    static func textQuake(distance: CGFloat = 5) -> AnyTransition {
        AnyTransition.modifier(
            active: TextQuakeModifier(progress: 0, distance: distance),
            identity: TextQuakeModifier(progress: 1, distance: distance)
        )
    }
}
