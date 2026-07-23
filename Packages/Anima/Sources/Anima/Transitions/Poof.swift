//  Poof.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import SwiftUI

@MainActor
public extension AnyTransition.MovingParts {
    /// A transition that removes the view in a dissolving cartoon style cloud.
    ///
    /// The transition is only performed on removal and takes 0.4 seconds.
    static var poof: AnyTransition {
        .asymmetric(
            insertion: .identity,
            removal: .modifier(
                active: Poof(animatableData: 0),
                identity: Poof(animatableData: 1)
            )
            .animation(.linear(duration: 0.4))
        )
    }
}

struct Poof: ViewModifier, ProgressableAnimation, AnimatableModifier {
    var animatableData: CGFloat = 0

    init(animatableData: CGFloat) {
        self.animatableData = animatableData
    }

    func body(content: Content) -> some View {
        let frame = (6 * progress).rounded()

        content
            .opacity(progress != 1 ? 0 : 1)
            .overlay(
                ZStack {
                    poof("poof1").opacity(frame == 5 ? 1 : 0)
                    poof("poof2").opacity(frame == 4 ? 1 : 0)
                    poof("poof3").opacity(frame == 3 ? 1 : 0)
                    poof("poof4").opacity(frame == 2 ? 1 : 0)
                    poof("poof5").opacity(frame == 1 ? 1 : 0)

                }
                .accessibilityHidden(true)
            )
            .animation(nil, value: progress)
    }

    func poof(_ name: String) -> some View {
        Image(name, bundle: .module)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 88, height: 88)
    }
}
