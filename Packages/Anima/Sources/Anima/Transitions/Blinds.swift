//  Blinds.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import SwiftUI

@MainActor
public extension AnyTransition.MovingParts {
    /// The style of blinds to use with a `blinds` transition.
    enum BlindsStyle: Sendable {
        /// Blinds with slats that cover the width of the view.
        case venetian
        /// Blinds with slats that cover the height of the view.
        case vertical
    }

    /// A transition that reveals the view as if it was behind window blinds.
    static var blinds: AnyTransition {
        blinds(slatWidth: 10)
    }

    /// A transition that reveals the view as if it was behind window blinds.
    ///
    /// - Parameters:
    ///   - slatWidth: The width of each slat.
    ///   - style: The style of blinds.
    ///   - isStaggered: Whether all slats opens at the same time or in sequence.
    static func blinds(slatWidth: CGFloat, style: BlindsStyle = .venetian, isStaggered: Bool = false) -> AnyTransition {
        let clampedHeight = clamp(5, slatWidth, .greatestFiniteMagnitude)

        return .modifier(
            active: Blinds(slatWidth: clampedHeight, style: style, isStaggered: isStaggered, animatableData: 0),
            identity: Blinds(slatWidth: clampedHeight, style: style, isStaggered: isStaggered, animatableData: 1)
        )
    }
}

struct Blinds: ViewModifier, ProgressableAnimation, AnimatableModifier, Hashable {
    var slatWidth: CGFloat

    var style: AnyTransition.MovingParts.BlindsStyle

    var isStaggered: Bool

    var animatableData: CGFloat

    func body(content: Content) -> some View {
        content
            .mask {
                BlindsShape(slatWidth: slatWidth, style: style, open: progress, isStaggered: isStaggered)
                    .flipsForRightToLeftLayoutDirection(true)
            }
    }
}

private struct BlindsShape: Shape {
    var slatWidth: CGFloat

    var style: AnyTransition.MovingParts.BlindsStyle

    var open: Double

    var isStaggered: Bool

    func path(in rect: CGRect) -> Path {
        let slatCount = switch style {
        case .venetian:
            Int((rect.height / slatWidth).rounded(.up))
        case .vertical:
            Int((rect.width / slatWidth).rounded(.up))
        }

        let slatRects = (0 ..< slatCount)
            .map { slatIndex -> CGRect in
                let progress: Double
                if isStaggered {
                    let fraction = 1.0 - (Double(slatIndex) / Double(slatCount))
                    progress = clamp(0.0, (open * 2.0 - 1.0) + fraction, 1.0)
                } else {
                    progress = open
                }

                let position = Double(slatIndex) * slatWidth + slatWidth * (1.0 - progress) / 2.0

                switch style {
                case .venetian:
                    return CGRect(
                        x: 0,
                        y: position,
                        width: rect.width,
                        height: slatWidth * progress
                    )
                case .vertical:
                    return CGRect(
                        x: position,
                        y: 0,
                        width: slatWidth * progress,
                        height: rect.height
                    )
                }
            }

        return Path { path in
            path.addRects(slatRects, transform: CGAffineTransform.identity)
        }
    }
}
