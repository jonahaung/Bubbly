//  Boing.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import SwiftUI
#if os(iOS) && EMG_PREVIEWS
    import SnapshotPreferences
#endif

@MainActor
public extension AnyTransition.MovingParts {
    /// A transition that moves the view down with any overshoot resulting in an
    /// elastic deformation of the view.
    static var boing: AnyTransition {
        boing(edge: .top)
    }

    /// A transition that moves the view from the specified edge on insertion,
    /// and towards it on removal, with any overshoot resulting in an elastic
    /// deformation of the view.
    static func boing(edge: Edge) -> AnyTransition {
        .modifier(
            active: Scaled(Boing(edge, animatableData: 0)),
            identity: Scaled(Boing(edge, animatableData: 1))
        )
    }
}

struct Boing: DebugProgressableAnimation, GeometryEffect {
    var edge: Edge

    var animatableData: CGFloat = 0

    init(_ edge: Edge, animatableData: CGFloat = 0) {
        self.animatableData = animatableData
        self.edge = edge
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let area = size.width * size.height

        var mainAxisSize: CGFloat {
            edge == .leading || edge == .trailing ? size.width : size.height
        }

        var crossAxisSize: CGFloat {
            edge == .leading || edge == .trailing ? size.height : size.width
        }

        let deltaP = -mainAxisSize * 2 * (1 - animatableData)

        var t = CGAffineTransform.identity

        if deltaP < 1 {
            let newMainAxisSize = rubberClamp(mainAxisSize / 2, mainAxisSize - deltaP / 3, mainAxisSize * 1.5)
            let newCrossAxisSize = area / newMainAxisSize

            t = t.translatedBy(x: size.width / 2, y: size.height / 2)

            switch edge {
            case .top:
                t = t.translatedBy(x: 0, y: deltaP)
            case .bottom:
                t = t.translatedBy(x: 0, y: -deltaP)
            case .leading:
                t = t.translatedBy(x: deltaP, y: 0)
            case .trailing:
                t = t.translatedBy(x: -deltaP, y: 0)
            }

            if edge == .leading || edge == .trailing {
                t = t.scaledBy(x: newMainAxisSize / mainAxisSize, y: newCrossAxisSize / crossAxisSize)
            } else {
                t = t.scaledBy(x: newCrossAxisSize / crossAxisSize, y: newMainAxisSize / mainAxisSize)
            }

            t = t.translatedBy(x: -size.width / 2, y: -size.height / 2)
        }

        if deltaP >= 5 {
            let deltaY = deltaP - 5

            let newMainAxisSize = rubberClamp(mainAxisSize * 0.75, mainAxisSize - deltaY / 3, mainAxisSize * 1)
            let newCrossAxisSize = area / newMainAxisSize

            let translation: CGAffineTransform = switch edge {
            case .top:
                CGAffineTransformMakeTranslation(size.width / 2, size.height)
            case .leading:
                CGAffineTransformMakeTranslation(size.width, size.height / 2)
            case .bottom:
                CGAffineTransformMakeTranslation(size.width / 2, 0)
            case .trailing:
                CGAffineTransformMakeTranslation(0, size.height / 2)
            }

            t = translation.concatenating(t)

            if edge == .leading || edge == .trailing {
                t = t.scaledBy(x: newMainAxisSize / mainAxisSize, y: newCrossAxisSize / crossAxisSize)
            } else {
                t = t.scaledBy(x: newCrossAxisSize / crossAxisSize, y: newMainAxisSize / mainAxisSize)
            }

            t = translation.inverted().concatenating(t)
        }

        return ProjectionTransform(t)
    }
}
private extension CGAffineTransform {
    init(skewX x: CGFloat, y: CGFloat) {
        self.init(a: 1, b: x, c: y, d: 1, tx: 0, ty: 0)
    }
}
