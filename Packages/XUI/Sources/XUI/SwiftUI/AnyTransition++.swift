//
//  ThumbnailExpandedModifier.swift
//  XUI
//
//  Created by Aung Ko Min on 31/12/25.
//

import SwiftUI

public extension EnvironmentValues {
    @Entry var modalTransitionPercent: CGFloat = 0
}

public extension AnyTransition {
    static var modal: AnyTransition {
        AnyTransition.modifier(
            active: ThumbnailExpandedModifier(pct: 0),
            identity: ThumbnailExpandedModifier(pct: 1)
        )
    }

	struct ThumbnailExpandedModifier: @preconcurrency AnimatableModifier {
        public var pct: CGFloat

        public var animatableData: CGFloat {
            get { pct }
            set { pct = newValue }
        }

        public func body(content: Content) -> some View {
            content
                .environment(\.modalTransitionPercent, pct)
                .opacity(1)
        }
    }

    /// This transition will cause the view to disappear,
    /// until the last frame of the animation is reached
    static var invisible: AnyTransition {
        AnyTransition.modifier(
            active: InvisibleModifier(pct: 0),
            identity: InvisibleModifier(pct: 1)
        )
    }

	struct InvisibleModifier: @preconcurrency AnimatableModifier {
        public var pct: Double

        public var animatableData: Double {
            get { pct }
            set { pct = newValue }
        }

        public func body(content: Content) -> some View {
            content.opacity(pct == 1.0 ? 1 : 0)
        }
    }
}
