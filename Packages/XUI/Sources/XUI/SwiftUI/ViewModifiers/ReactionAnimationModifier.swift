//
//  ReactionAnimationModifier.swift
//  HomeForYou
//
//  Created by Aung Ko Min on 14/6/24.
//

import SwiftUI

@MainActor
private struct ReactionAnimationModifier<T: Equatable & Sendable>: ViewModifier {
    struct AnimationValues {
        var scale = 1.0
        var verticalStretch = 1.0
        var angle = Angle.zero
        var offset: CGSize = .zero
    }

    var trigger: T
    var offset: CGSize

    func body(content: Content) -> some View {
        content
            .keyframeAnimator(
                initialValue: AnimationValues(),
                trigger: trigger
            ) { content, value in
                content
                    .rotationEffect(value.angle)
                    .scaleEffect(value.scale)
                    .scaleEffect(value.verticalStretch)
                    .offset(value.offset)
            } keyframes: { _ in
//                KeyframeTrack(\.scale) {
//                    LinearKeyframe(1.0, duration: 0.36)
//                    SpringKeyframe(1.5, duration: 0.8, spring: .bouncy)
//                    SpringKeyframe(1.0, spring: .bouncy)
//                }
                KeyframeTrack(\.offset) {
                    LinearKeyframe(.zero, duration: 0.36)
                    SpringKeyframe(offset, duration: 0.8, spring: .bouncy)
                    SpringKeyframe(.zero, spring: .bouncy)
                }

//                KeyframeTrack(\.verticalStretch) {
//                    CubicKeyframe(1.0, duration: 0.1)
//                    CubicKeyframe(0.6, duration: 0.15)
//                    CubicKeyframe(2, duration: 0.1)
//                    CubicKeyframe(1.05, duration: 0.15)
//                    CubicKeyframe(1.0, duration: 0.88)
//                    CubicKeyframe(0.8, duration: 0.1)
//                    CubicKeyframe(1.04, duration: 0.4)
//                    CubicKeyframe(1.0, duration: 0.22)
//                }
//                KeyframeTrack(\.angle) {
//                    CubicKeyframe(.zero, duration: 0.58)
//                    CubicKeyframe(.degrees(20), duration: 0.125)
//                    CubicKeyframe(.degrees(-16), duration: 0.125)
//                    CubicKeyframe(.degrees(20), duration: 0.125)
//                    CubicKeyframe(.zero, duration: 0.125)
//                }
            }
    }
}

public extension View {
    func withReactionAnimation(_ trigger: some Equatable & Sendable, offset: CGSize = .zero) -> some View {
        modifier(ReactionAnimationModifier(trigger: trigger, offset: offset))
    }
}
