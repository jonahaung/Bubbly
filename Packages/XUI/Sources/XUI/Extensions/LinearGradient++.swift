//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

public extension LinearGradient {
    static func fading(
        _ color: Color,
        startPoint: UnitPoint = .top,
        endPoint: UnitPoint = .bottom
    ) -> Self {
        .init(colors: [
            color,
            color.opacity(0)
        ], startPoint: startPoint, endPoint: endPoint)
    }
}
