//  Wipe.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import SwiftUI

@MainActor
public extension AnyTransition.MovingParts {
    /// A transition using a sweep from the specified edge on insertion, and
    /// towards it on removal.
    ///
    /// - Parameters:
    ///   - edge: The edge at which the sweep starts or ends.
    ///   - blurRadius: The radius of the blur applied to the mask.
    static func wipe(edge: Edge, blurRadius: CGFloat = 0) -> AnyTransition {
        let angle: Angle = switch edge {
        case .top:
            .degrees(90)
        case .leading:
            .degrees(0)
        case .bottom:
            .degrees(270)
        case .trailing:
            .degrees(180)
        }

        return .modifier(
            active: Wipe(angle: angle, blurRadius: blurRadius, progress: 0),
            identity: Wipe(angle: angle, blurRadius: blurRadius, progress: 1)
        )
    }

    /// A transition using a sweep at the specified angle.
    ///
    /// The angle is relative to the current `layoutDirection`, such that 0° represents sweeping towards the trailing edge on insertion and 90° represents sweeping towards the bottom edge.
    ///
    /// In this example, the view insertion is animated by sweeping diagonally
    /// from the top leading corner towards the bottom trailing corner.
    ///
    /// ```swift
    /// Text("Hello")
    ///     .transition(
    ///         .asymmetric(
    ///             insertion: .movingParts.wipe(angle: .degrees( 45), blurRadius: 10),
    ///             removal:   .movingParts.wipe(angle: .degrees(225), blurRadius: 10)
    ///         )
    ///     )
    /// ```
    ///
    /// - Parameters:
    ///   - angle: The angle of the animation.
    ///   - blurRadius: The radius of the blur applied to the mask.
    static func wipe(angle: Angle, blurRadius: CGFloat = 0) -> AnyTransition {
        .modifier(
            active: Wipe(angle: angle, blurRadius: blurRadius, progress: 0),
            identity: Wipe(angle: angle, blurRadius: blurRadius, progress: 1)
        )
    }
}

@MainActor
private struct Wipe: ViewModifier, @MainActor Animatable, @MainActor AnimatableModifier {
    var angle: Angle

    var animatableData: AnimatablePair<CGFloat, CGFloat>

    init(angle: Angle, blurRadius: CGFloat = 0, progress: CGFloat) {
        self.angle = angle
        animatableData = AnimatableData(progress, clamp(0, blurRadius, 30))
    }

    var progress: CGFloat {
        animatableData.first
    }

    var blurRadius: CGFloat {
        animatableData.second
    }

    func body(content: Content) -> some View {
        content
            .mask(
                GeometryReader { proxy in
                    mask(size: proxy.size)
                        .blur(radius: blurRadius * (1 - progress))
                        .compositingGroup()
                }
                .padding(-blurRadius)
                .animation(nil, value: animatableData)
            )
    }

    @ViewBuilder
    func mask(size: CGSize) -> some View {
        let bounds = CGRect(origin: .zero, size: size).boundingBox(at: angle)

        ZStack(alignment: .leading) {
            Color.clear

            Rectangle()
                .frame(width: progress * bounds.width)
        }
        .frame(width: bounds.width, height: bounds.height)
        .position(
            x: bounds.midX,
            y: bounds.midY
        )
        .rotationEffect(angle)
        .animation(nil, value: progress)
        .animation(nil, value: angle)
    }
}
