//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

public struct AnimatedGradientBackground: View {
    public enum Theme: CaseIterable, Sendable {
        case blue
        case red
        case orange
        case grey
        case brown
        case green
        case purple
        case yellow
    }

    private let theme: Theme

    public init(_ theme: Theme = .grey) {
        self.theme = theme
    }

    public var body: some View {
        TimelineView(.animation) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            let offsetX = Float(sin(time * 0.4)) * 0.08
            let offsetY = Float(cos(time * 0.3)) * 0.08

            AnimatedMeshGradientShape(
                theme: theme,
                offsetX: offsetX,
                offsetY: offsetY
            )
            .ignoresSafeArea()
        }
    }
}
