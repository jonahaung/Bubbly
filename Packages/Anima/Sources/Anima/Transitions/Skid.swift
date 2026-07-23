//  Skid.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import SwiftUI
#if os(iOS) && EMG_PREVIEWS
    import SnapshotPreferences
#endif

@MainActor
public extension AnyTransition.MovingParts {
    /// The direction from which to animate in during a `skid` transition's insertion.
    enum SkidDirection {
        case leading
        case trailing
    }

    /// A transition that moves the view in from its leading edge with any
    /// overshoot resulting in an elastic deformation of the view.
    static var skid: AnyTransition {
        skid(direction: .leading)
    }

    /// A transition that moves the view in from the specified edge during
    /// insertion and towards it during removal with any overshoot resulting
    /// in an elastic deformation of the view.
    ///
    /// - Parameter direction: The direction of the transition.
    static func skid(direction: SkidDirection) -> AnyTransition {
        .modifier(
            active: Scaled(Skid(direction, animatableData: 0)),
            identity: Scaled(Skid(direction, animatableData: 1))
        )
    }
}

struct Skid: DebugProgressableAnimation, GeometryEffect {
    var direction: AnyTransition.MovingParts.SkidDirection

    var animatableData: CGFloat = 0

    init(_ direction: AnyTransition.MovingParts.SkidDirection, animatableData: CGFloat = 0) {
        self.animatableData = animatableData
        self.direction = direction
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let deltaX = -size.width * 2 * (1 - animatableData)

        var t = CGAffineTransform.identity

        t = t.translatedBy(x: size.width / 2, y: size.height / 2)

        let clampedDeltaX = deltaX

        t = switch direction {
        case .leading:
            t.translatedBy(x: clampedDeltaX, y: 0)
        case .trailing:
            t.translatedBy(x: -clampedDeltaX, y: 0)
        }

        let newMainAxisSize = clamp(size.width / 2, size.width - deltaX, size.width * 1.5)

        switch direction {
        case .leading:
            t = t.translatedBy(x: -size.width * (-1 + (newMainAxisSize / size.width)), y: 0)
            t = CGAffineTransformShear(t, -1 + (newMainAxisSize / size.width), 0)
        case .trailing:
            t = t.translatedBy(x: -size.width * (1 - (newMainAxisSize / size.width)), y: 0)
            t = CGAffineTransformShear(t, 1 - (newMainAxisSize / size.width), 0)
        }

        t = t.translatedBy(x: -size.width / 2, y: -size.height / 2)

        return ProjectionTransform(t)
    }
}
private extension CGAffineTransform {
    init(skewX x: CGFloat, y: CGFloat) {
        self.init(a: 1, b: x, c: y, d: 1, tx: 0, ty: 0)
    }
}
