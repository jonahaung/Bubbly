//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

public struct AnimatedMeshGradientShape: View {
    public let theme: AnimatedGradientBackground.Theme
    public let offsetX: Float
    public let offsetY: Float

    public init(
        theme: AnimatedGradientBackground.Theme,
        offsetX: Float,
        offsetY: Float
    ) {
        self.theme = theme
        self.offsetX = offsetX
        self.offsetY = offsetY
    }

    public var body: some View {
        MeshGradient(
            width: 4,
            height: 4,
            points: meshPoints,
            colors: palette
        )
    }

    private var meshPoints: [SIMD2<Float>] {
        [
            SIMD2(0.0, 0.0), SIMD2(0.3, 0.0), SIMD2(0.7, 0.0), SIMD2(1.0, 0.0),

            SIMD2(0.0, 0.3),
            SIMD2(0.25 + offsetX, 0.35 + offsetY),
            SIMD2(0.75 + offsetX, 0.25 + offsetY),
            SIMD2(1.0, 0.3),

            SIMD2(0.0, 0.7),
            SIMD2(0.3 + offsetX, 0.75),
            SIMD2(0.7 + offsetX, 0.65),
            SIMD2(1.0, 0.7),

            SIMD2(0.0, 1.0), SIMD2(0.3, 1.0), SIMD2(0.7, 1.0), SIMD2(1.0, 1.0)
        ]
    }

    private var palette: [Color] {
        let base = baseColor

        return [
            base.opacity(0.25), base.opacity(0.4), .white, base.opacity(0.3),
            .white, base.opacity(0.35), base.opacity(0.5), .white,
            base.opacity(0.45), .white, base.opacity(0.3), base.opacity(0.55),
            .white, base.opacity(0.4), base.opacity(0.35), base.opacity(0.5)
        ]
    }

    private var baseColor: Color {
        switch theme {
        case .blue: .blue
        case .red: .red
        case .orange: .orange
        case .grey: .gray
        case .brown: .brown
        case .green: .green
        case .purple: .purple
        case .yellow: .yellow
        }
    }
}
