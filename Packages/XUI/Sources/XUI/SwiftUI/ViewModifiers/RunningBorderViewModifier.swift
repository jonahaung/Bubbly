//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

struct RunningBorderViewModifier: ViewModifier {
    let lineWidth: CGFloat
    let cornerRadius: CGFloat
    let animated: Bool

    @State private var rotation: Double = 0

    func body(content: Content) -> some View {
        content
            .padding(lineWidth)
            .background(
                ContainerRelativeShape()
                    .strokeBorder(
                        AngularGradient(
                            gradient: Gradient(
                                colors: animated ? [.indigo, .blue, .red, .orange, .indigo] :
                                    [Color.accentColor]
                            ),
                            center: .center,
                            startAngle: .degrees(rotation),
                            endAngle: .degrees(rotation + 360)
                        ),
                        lineWidth: lineWidth
                    )
            )
            .onAppear {
                guard animated else { return }
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
            .onChange(of: animated) { _, newValue in
                if newValue {
                    rotation = 0
                    withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                } else {
                    rotation = 0
                }
            }
    }
}

public extension View {
    func runningBorder(
        lineWidth: CGFloat = 1,
        cornerRadius: CGFloat,
        animated: Bool = true
    ) -> some View {
        modifier(RunningBorderViewModifier(
            lineWidth: lineWidth,
            cornerRadius: cornerRadius,
            animated: animated
        ))
    }
}
