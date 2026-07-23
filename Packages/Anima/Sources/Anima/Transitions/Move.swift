//  Move.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import simd
import SwiftUI

@MainActor
public extension AnyTransition.MovingParts {
    /// A transition that moves the view from the specified edge of the on
    /// insertion and towards it on removal.
    static func move(edge: Edge) -> AnyTransition {
        .modifier(
            active: Scaled(Move(edge: edge)),
            identity: Scaled(Move())
        )
    }

    /// A transition that moves the view at the specified angle.
    ///
    /// The angle is relative to the current `layoutDirection`, such that 0° represents animating towards the trailing edge on insertion and 90° represents inserting towards the bottom edge.
    ///
    /// In this example, the view insertion is animated by moving it towards the top trailing corner and the removal is animated by moving it towards the bottom edge.
    ///
    /// ```swift
    /// Text("Hello")
    ///     .transition(
    ///         .asymmetric(
    ///             insertion: .movingParts.move(angle: .degrees(45)),
    ///             removal:   .movingParts.move(angle: .degrees(90))
    ///         )
    ///     )
    /// ```
    ///
    /// - Parameter angle: The direction of the animation.
    static func move(angle: Angle) -> AnyTransition {
        .modifier(
            active: Scaled(Move(angle: angle)),
            identity: Scaled(Move())
        )
    }
}

struct Move: GeometryEffect, Animatable {
    /// Translation is relative, depth is ignored, anchor is always
    /// `UnitPoint(0.5, 0.5)`.
    var animatableData: TRS = .identity

    init(edge: Edge) {
        switch edge {
        case .top:
            animatableData.translation.y = -1
        case .leading:
            animatableData.translation.x = -1
        case .bottom:
            animatableData.translation.y = 1
        case .trailing:
            animatableData.translation.x = 1
        }
    }

    init() {}

    init(angle: Angle) {
        let u = cos(angle.radians)
        let v = sin(angle.radians)

        let u_2: Double = pow(u, 2)
        let v_2: Double = pow(v, 2)
        let sq2: Double = sqrt(2.0)

        let x = 0.5 * sqrt(abs(2.0 + u_2 - v_2 + 2.0 * u * sq2)) - 0.5 * sqrt(abs(2.0 + u_2 - v_2 - 2.0 * u * sq2))
        let y = 0.5 * sqrt(abs(2.0 - u_2 + v_2 + 2.0 * v * sq2)) - 0.5 * sqrt(abs(2.0 - u_2 + v_2 - 2.0 * v * sq2))

        animatableData.translation.x = -x
        animatableData.translation.y = -y
    }

    private var trs: TRS {
        get { animatableData }
        set { animatableData = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let anchor = UnitPoint.center

        let offset = simd_double4x4(translationX: size.width * anchor.x, y: size.height * anchor.y)

        let translation = simd_double4x4(translationX: trs.translation.x * size.width, y: trs.translation.y * size.height, z: 0)

        let rotation = simd_double4x4(trs.rotation.normalized)

        let scale = simd_double4x4(scaleX: trs.scale.x, y: trs.scale.y, z: 1)

        return ProjectionTransform((((offset * translation) * rotation) * scale) * offset.inverse)
    }
}
