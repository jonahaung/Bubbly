//  LinearGradient++.swift
//
//  Copyright © 2026 Aung Ko Min.
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
