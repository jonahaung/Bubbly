//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import SwiftUI

public struct LoadingIndicator: View {
    
    static let gradient = AngularGradient(
        gradient: Gradient(colors: [.white, .yellow, .orange, .red, .pink, .blue, .indigo]),
        center: .center
    )
    
    private let size: CGFloat
    private let lineWidth: CGFloat
    private let progress: Double?
    @State private var isAnimating = false

    public init(
        _ size: CGFloat,
        lineWidth: CGFloat = 2,
        progress: Double? = nil
    ) {
        self.size = size
        self.lineWidth = lineWidth
        self.progress = progress
    }

    public var body: some View {
        FixedSizeCenterLayout(square: size) {
            if let progress {
                determinate(progress: progress)
            } else {
                indeterminate
            }
        }
    }

    private var indeterminate: some View {
        Circle()
            .trim(from: 0.1, to: 1)
            .stroke(
                Self.gradient,
                style: StrokeStyle(
                    lineWidth: lineWidth,
                    lineCap: .round
                )
            )
            .rotationEffect(.degrees(isAnimating ? 360 : 0))
            .animation(
                .linear(duration: 1)
                    .repeatForever(autoreverses: false),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }

    private func determinate(progress: Double) -> some View {
        let clamped = min(max(progress, 0), 1)
        return ZStack {
            Circle()
                .stroke(
                    Color.primary.opacity(0.12),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
            Circle()
                .trim(from: 0, to: clamped)
                .stroke(
                    Self.gradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
    }
}
