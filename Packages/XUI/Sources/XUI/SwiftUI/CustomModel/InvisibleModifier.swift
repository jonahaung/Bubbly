//  InvisibleModifier.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import SwiftUI

struct InvisibleModifier: @MainActor AnimatableModifier {
    var percent: CGFloat
    var animatableData: CGFloat {
        get { percent }
        set { percent = newValue }
    }

    func body(content: Content) -> some View {
        content.opacity(percent == 1.0 ? 1 : 0)
    }
}
