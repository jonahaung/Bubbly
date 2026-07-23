//  GlowEffect.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import SwiftUI

@MainActor
public extension AnyChangeEffect {
    /// An effect that highlights the view with a glow around it.
    ///
    /// The glow appears for a second.
    static var glow: AnyChangeEffect {
        glow(color: .accentColor)
    }

    /// An effect that highlights the view with a glow around it.
    ///
    /// The glow appears for a second.
    ///
    /// - Parameters:
    ///   - color: The color of the glow.
    ///   - radius: The radius of the glow.
    static func glow(color: Color, radius: CGFloat = 16) -> AnyChangeEffect {
        .simulation { change in
            PulseGlowModifier(impulseCount: change, color: color, radius: min(100, radius))
        }
    }
}

@MainActor
public extension AnyConditionalEffect {
    /// An effect that highlights the view with a glow around it.
    static var glow: AnyConditionalEffect {
        glow(color: .accentColor)
    }

    /// An effect that highlights the view with a glow around it.
    ///
    /// - Parameters:
    ///   - color: The color of the glow.
    ///   - radius: The radius of the glow.
    static func glow(color: Color, radius: CGFloat = 16) -> AnyConditionalEffect {
        .continuous(
            .modifier { isActive in
                ContinuousGlowModifier(color: color, radius: radius, isActive: isActive)
            }
        )
    }
}

struct GlowModifier: ViewModifier, Animatable {
    var animatableData: CGFloat

    var color: Color

    var radius: CGFloat

    let ramp = cubicBezier(x1: 0.3, y1: 0.0, x2: 0.7, y2: 1)

    init(glow: CGFloat, color: Color, radius: CGFloat) {
        animatableData = glow
        self.color = color
        self.radius = radius
    }

    var glow: CGFloat {
        get { animatableData }
        set { animatableData = newValue }
    }

    func body(content: Content) -> some View {
        let amount = min(glow, 1.5)

        let shadowOpacity = sqrt(amount)

        content
            .transformEnvironment(\.backgroundMaterial) { material in
                material = nil
            }
            .overlay {
                color
                    .opacity(ramp(amount))
                    .blendMode(.sourceAtop)
                    .brightness(ramp(abs(amount)) * 0.1)
                    .allowsHitTesting(false)
            }
            .compositingGroup()
            .shadow(color: color.opacity(shadowOpacity / 1.2), radius: amount * radius / 4.0, x: 0, y: 0)
            .shadow(color: color.opacity(shadowOpacity / 4.0), radius: amount * radius / 2.0, x: 0, y: 0)
            .shadow(color: color.opacity(shadowOpacity / 8.0), radius: amount * radius, x: 0, y: 0)
            .shadow(color: color.opacity(shadowOpacity / 16.0), radius: amount * radius * 2.0, x: 0, y: 0)
            .brightness(ramp(abs(amount)) * 0.25)
            .animation(nil, value: amount)
    }
}

struct ContinuousGlowModifier: ViewModifier, Continuous {
    var color: Color

    var radius: CGFloat

    var isActive: Bool

    func body(content: Content) -> some View {
        content
            .modifier(
                GlowModifier(glow: isActive ? 0.7 : 0, color: color, radius: radius)
                    .animation(.easeInOut(duration: 0.25))
            )
    }
}

struct PulseGlowModifier: ViewModifier, Simulative {
    var impulseCount: Int

    var initialVelocity: CGFloat = 0

    let spring: Spring = .init(zeta: 0.75, stiffness: 15, mass: 1)

    var color: Color

    var radius: CGFloat

    @State
    private var targetGlow: CGFloat = 0.0

    @State
    private var glow: CGFloat = 0.0

    @State
    private var glowVelocity: CGFloat = 0.0

    private var isSimulationPaused: Bool {
        targetGlow == glow && abs(glowVelocity) <= 0.02
    }

    func body(content: Content) -> some View {
        TimelineView(.animation(paused: isSimulationPaused)) { context in
            content
                .modifier(GlowModifier(glow: glow, color: color, radius: radius))
                .onChange(of: context.date) { (newValue: Date) in
                    let duration = Double(newValue.timeIntervalSince(context.date))
                    withAnimation(nil) {
                        update(clamp(0, duration, 1 / 30))
                    }
                }
        }
        .onChange(of: impulseCount) { newValue in
            withAnimation(nil) {
                if glowVelocity <= 0.05 {
                    glowVelocity = 5
                } else {
                    glowVelocity += 1.5
                }

                glowVelocity = min(glowVelocity, 5)
            }
        }
    }

    private func update(_ step: Double) {
        let newValue: Double
        let newVelocity: Double

        if spring.response > 0 {
            (newValue, newVelocity) = spring.value(
                from: glow,
                to: targetGlow,
                velocity: glowVelocity,
                timestep: step
            )
        } else {
            newValue = targetGlow
            newVelocity = 0.0
        }

        glow = newValue
        glowVelocity = newVelocity

        if abs(newValue - targetGlow) < 0.01, newVelocity < 0.01 {
            glow = targetGlow
            glowVelocity = 0.0
        }
    }
}
