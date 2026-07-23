//  Pop.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import simd
import SwiftUI

@MainActor
public extension AnyTransition.MovingParts {
    /// A transition that shows a view with a ripple effect and a flurry of
    /// tint-colored particles.
    ///
    /// The transition is only performed on insertion and takes 1.2 seconds.
    static var pop: AnyTransition {
        pop(.tint)
    }

    /// A transition that shows a view with a ripple effect and a flurry of
    /// colored particles.
    ///
    /// In this example, the star uses the pop effect only when transitioning
    /// from `starred == false` to `starred == true`:
    ///
    /// ```swift
    /// Button {
    ///     starred.toggle()
    /// } label: {
    ///     if starred {
    ///         Image(systemName: "star.fill")
    ///             .foregroundStyle(.orange)
    ///             .transition(.movingParts.pop(.orange))
    ///     } else {
    ///         Image(systemName: "star")
    ///             .foregroundStyle(.gray)
    ///             .transition(.identity)
    ///     }
    /// }
    /// ```
    ///
    /// The transition is only performed on insertion.
    ///
    /// - Parameter style: The style to use for the effect.
    static func pop(_ style: some ShapeStyle) -> AnyTransition {
        let pop = AnyTransition
            .modifier(
                active: Pop(style: AnyShapeStyle(style), animatableData: 0),
                identity: Pop(style: AnyShapeStyle(style), animatableData: 1)
            )
            .animation(.linear(duration: 1.2))

        return .asymmetric(
            insertion: pop,
            removal: .identity
        )
    }
}

@available(iOS 15.0, *)
struct Pop: AnimatableModifier, ProgressableAnimation, ViewModifier {
    var animatableData: CGFloat = 0

    var style: AnyShapeStyle

    var seed: CGFloat = .random(in: 0 ... 255)

    init(style: AnyShapeStyle, animatableData: CGFloat) {
        self.animatableData = animatableData
        self.style = style
    }

    func body(content: Content) -> some View {
        let t = clamp(2 * (progress - 1 / 2.5))

        content
            .scaleEffect(1 - pow(2, -20 * t))
            .overlay {
                circleOverlay
            }
            .background {
                particles
            }
            .animation(nil, value: progress)
    }

    @ViewBuilder
    var particles: some View {
        let t = clamp(2 * (progress - 1 / 3))

        var rng = SeededRandomNumberGenerator(seed: seed)

        Canvas { ctx, size in
            if t == 0 { return }

            let particleSize = CGSize(width: 3, height: 3)

            let particleCount = 20

            let radius: CGFloat = min(size.width, size.height) - 22

            for p in 0 ..< particleCount {
                let f = CGFloat.random(in: 0.95 ... 1.1, using: &rng)

                let particleT = clamp(f * (t - (1 - 1 / f)))

                if particleT <= 0 { return }

                let particleOpacity: CGFloat = if particleT < 0.5 {
                    1 - pow(2, -20 * particleT)
                } else {
                    1 - pow(2, 10 * (particleT - 1))
                }

                if particleOpacity <= 0 { return }

                let p = CGFloat(p)
                let pFrac: CGFloat = p / CGFloat(particleCount)

                let yOffset = CGFloat.random(in: -2 ... 2, using: &rng)

                let scale = easeOut(1 - particleT) * CGFloat.random(in: 0.8 ... 1.4, using: &rng)

                ctx.drawLayer { ctx in
                    ctx.translateBy(x: size.width / 2, y: size.height / 2)

                    ctx.rotate(by: .degrees(360 * pFrac + CGFloat.random(in: -5 ... 5, using: &rng)))
                    ctx.translateBy(
                        x: 0,
                        y: lerp(easeOut(particleT), outMin: 0, outMax: radius / 2 + yOffset)
                    )
                    ctx.scaleBy(x: scale, y: scale)

                    ctx.opacity = clamp(particleOpacity)

                    ctx.addFilter(.hueRotation(.degrees(.random(in: -25 ... 25, using: &rng))))

                    let c = Circle().path(in: CGRect(center: .zero, size: particleSize))
                    ctx.fill(c, with: .style(style))
                }
            }
        }
        .padding(-30)
        .aspectRatio(1, contentMode: .fit)
        .allowsHitTesting(false)
    }

    @ViewBuilder
    var circleOverlay: some View {
        let t1 = clamp(1.5 * progress)
        let t2 = clamp(1.5 * (progress - 0.15))

        ZStack {
            Circle()
                .fill(AnyShapeStyle(style))
                .scaleEffect(1 - pow(2, -14 * t1))

            Circle()
                .foregroundColor(.white)
                .scaleEffect(1 - pow(2, -14 * t2))
                .blendMode(.destinationOut)
        }
        .compositingGroup()
        .opacity(
            clamp(1 - pow(1.3, -20 * Double(1 - t1)))
        )
        .padding(-8)
        .allowsHitTesting(false)
    }
}
