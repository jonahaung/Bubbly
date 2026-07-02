//  GradientForegroundStyle.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import SwiftUI

struct GradientForegroundStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.foregroundStyle(
            LinearGradient(
                colors: [
                    Color(red: 0.259, green: 0.522, blue: 0.957),
                    Color(red: 0.608, green: 0.447, blue: 0.796),
                    Color(red: 0.851, green: 0.396, blue: 0.439),
                    Color(red: 0.851, green: 0.396, blue: 0.439)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }
}

struct MovingGradientForegroundStyle: ViewModifier {
    @State private var animateGradient = false

    func body(content: Content) -> some View {
        content.overlay(
            LinearGradient(
                colors: [
                    Color(red: 0.259, green: 0.522, blue: 0.957),
                    Color(red: 0.608, green: 0.447, blue: 0.796),
                    Color(red: 0.259, green: 0.522, blue: 0.957),
                    Color(red: 0.608, green: 0.447, blue: 0.796)
                ],
                startPoint: animateGradient ? .leading : .trailing,
                endPoint: animateGradient ? .trailing : .leading
            )
            .animation(
                .linear(duration: 3).repeatForever(autoreverses: false),
                value: animateGradient
            )
        )
        .mask(content)
        .onAppear {
            animateGradient = true
        }
    }
}

public extension View {
    func gradientBackground() -> some View {
        modifier(GradientForegroundStyle())
    }

    func movingGradientBackground() -> some View {
        modifier(MovingGradientForegroundStyle())
    }
}
