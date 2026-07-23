//  Swoosh.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import simd
import SwiftUI

@MainActor
public extension AnyTransition.MovingParts {
    /// A three-dimensional transition from the back of the towards the front
    /// during insertion and from the front towards the back during removal.
    static var swoosh: AnyTransition {
        .modifier(
            active: Transform3DEffect(
                translation: [-100, -50, -2500],
                rotation:
                simd_quatd(angle: Angle(degrees: -85).radians, axis: [1, 0, 0]) *
                    simd_quatd(angle: Angle(degrees: 45).radians, axis: [0, 1, 0]) *
                    simd_quatd(angle: Angle(degrees: 10).radians, axis: [0, 0, 1]),

                anchor: .top,
                anchorZ: -20,
                perspective: 0.16
            ),
            identity: Transform3DEffect(perspective: 0.16)
        )
    }
}
