//
//  ReactionKeyframeModifier.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 3/11/25.
//

import SwiftUI

public struct ReactionKeyframeProperties {
    public var scale = 1.0
    public var verticalStretch = 1.0
    public var verticalTranslation = 0.0
    public var rotation = Angle.zero
    public var hueRotation = Angle.zero

    public init() {}
}

public struct ReactionKeyframeModifier: ViewModifier {
    @Binding public var trigger: Int

    public init(trigger: Binding<Int>) {
        self._trigger = trigger
    }

    public func body(content: Content) -> some View {
        content
            .keyframeAnimator(
                initialValue: ReactionKeyframeProperties(),
                trigger: trigger
            ) { content, value in
                content
                    .rotationEffect(value.rotation)
                    .hueRotation(value.hueRotation)
                    .scaleEffect(value.scale)
                    .scaleEffect(y: value.verticalStretch)
                    .offset(y: value.verticalTranslation)
            } keyframes: { _ in

                KeyframeTrack(\.rotation) {
                    CubicKeyframe(.zero, duration: 0.58)
                    CubicKeyframe(.degrees(16), duration: 0.125)
                    CubicKeyframe(.degrees(-16), duration: 0.125)
                    CubicKeyframe(.degrees(16), duration: 0.125)
                    CubicKeyframe(.zero, duration: 0.125)
                }

                KeyframeTrack(\.verticalStretch) {
                    CubicKeyframe(1.0, duration: 0.1)
                    CubicKeyframe(0.6, duration: 0.15)
                    CubicKeyframe(1.5, duration: 0.1)
                    CubicKeyframe(1.05, duration: 0.15)
                    CubicKeyframe(1.0, duration: 0.88)
                    CubicKeyframe(0.8, duration: 0.1)
                    CubicKeyframe(1.04, duration: 0.4)
                    CubicKeyframe(1.0, duration: 0.22)
                }

                KeyframeTrack(\.scale) {
                    LinearKeyframe(1.0, duration: 0.36)
                    SpringKeyframe(2.0, duration: 0.8, spring: .bouncy)
                    SpringKeyframe(1, spring: .bouncy)
                }

                KeyframeTrack(\.verticalTranslation) {
                    LinearKeyframe(0.0, duration: 0.1)
                    SpringKeyframe(20.0, duration: 0.15, spring: .bouncy)
                    SpringKeyframe(-60.0, duration: 1.0, spring: .bouncy)
                    SpringKeyframe(0.0, spring: .bouncy)
                }

                KeyframeTrack(\.hueRotation) {
                    LinearKeyframe(.zero, duration: 0.58)
                    LinearKeyframe(.degrees(45), duration: 0.125)
                    LinearKeyframe(.degrees(-30), duration: 0.125)
                    LinearKeyframe(.degrees(150), duration: 0.125)
                    LinearKeyframe(.zero, duration: 0.125)
                }
            }
    }
}
public extension View {
    func reactionAnimation(trigger: Binding<Int>) -> some View {
        self.modifier(ReactionKeyframeModifier(trigger: trigger))
    }
}
