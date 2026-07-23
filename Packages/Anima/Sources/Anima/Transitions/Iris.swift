//  Iris.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import SwiftUI

@MainActor
public extension AnyTransition.MovingParts {
    /// A transition that takes the shape of a growing circle when inserting,
    /// and a shrinking circle when removing.
    ///
    /// - Parameters:
    ///   - origin: The center point of the circle as it grows or shrinks.
    ///   - blurRadius: The radius of the blur applied to the mask.
    static func iris(origin: UnitPoint = .center, blurRadius: CGFloat = 0) -> AnyTransition {
        .modifier(
            active: Iris(origin: origin, blurRadius: blurRadius, animatableData: 0),
            identity: Iris(origin: origin, blurRadius: blurRadius, animatableData: 1)
        )
    }
}

@MainActor
struct Iris: ViewModifier, @MainActor DebugProgressableAnimation, @MainActor AnimatableModifier {
    var origin: UnitPoint

    var blurRadius: CGFloat

    var animatableData: CGFloat = 0

    init(origin: UnitPoint, blurRadius: CGFloat = 0, animatableData: CGFloat) {
        self.origin = origin
        self.blurRadius = clamp(0, blurRadius, 30)
        self.animatableData = animatableData
    }

    var progress: CGFloat {
        get { animatableData }
        set { animatableData = newValue }
    }

    func body(content: Content) -> some View {
        content
            .mask(
                GeometryReader { proxy in
                    let width = proxy.size.width
                    let height = proxy.size.height

                    let scaledWidth = width * 2 * max(origin.x, 1 - origin.x)
                    let scaledHeight = height * 2 * max(origin.y, 1 - origin.y)

                    let diagonal = progress * sqrt(scaledWidth * scaledWidth + scaledHeight * scaledHeight)

                    Circle()
                        .frame(width: diagonal, height: diagonal)
                        .position(
                            x: origin.x * width,
                            y: origin.y * height
                        )
                        .blur(radius: (1 - progress) * blurRadius)
                }
            )
    }
}
