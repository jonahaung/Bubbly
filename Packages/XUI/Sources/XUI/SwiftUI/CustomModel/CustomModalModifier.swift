//  CustomModalModifier.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import SwiftUI

public extension EnvironmentValues {
    @Entry var transitionProgress: CGFloat = 0
}

extension AnyTransition {
    struct CustomModalModifier: @MainActor AnimatableModifier {
        let edge: Edge
        var progress: CGFloat

        var animatableData: CGFloat {
            get { progress }
            set { progress = newValue }
        }

        func body(content: Content) -> some View {
            GeometryReader { proxy in
                content
                    .transformEffect(transform(for: proxy.size))
                    .environment(\.transitionProgress, progress)
            }
        }

        private func transform(for size: CGSize) -> CGAffineTransform {
            let translation =
                switch edge {
                case .bottom:
                    CGPoint(x: 0, y: size.height * (1 - progress))
                case .top:
                    CGPoint(x: 0, y: -size.height * (1 - progress))
                case .leading:
                    CGPoint(x: -size.width * (1 - progress), y: 0)
                case .trailing:
                    CGPoint(x: size.width * (1 - progress), y: 0)
                }
            return CGAffineTransform(
                translationX: translation.x,
                y: translation.y
            )
        }
    }
}

public extension AnyTransition {
    @MainActor
    static func modal(
        edge: Edge,
        curve: Animation? = nil
    ) -> AnyTransition {
        let base = AnyTransition.modifier(
            active: CustomModalModifier(edge: edge, progress: 0),
            identity: CustomModalModifier(edge: edge, progress: 1)
        )
        if let curve {
            return base.animation(curve)
        } else {
            return base
        }
    }
}
