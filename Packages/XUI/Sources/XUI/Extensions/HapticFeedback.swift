//  HapticFeedback.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import SwiftUI
import Foundation

public extension View {
    private func performHapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    func impactFeedbackOnTap(style: UIImpactFeedbackGenerator.FeedbackStyle = .light, isEnabled: Bool = true) -> some View {
        onTapGesture {
            if isEnabled {
                self.performHapticFeedback(style: style)
            }
        }
    }

    func simultaneousImpactFeedbackOnTap(
        style: UIImpactFeedbackGenerator.FeedbackStyle = .light,
        isEnabled: Bool = true
    ) -> some View {
        simultaneousGesture(TapGesture().onEnded { _ in
            if isEnabled {
                self.performHapticFeedback(style: style)
            }
        })
    }

    func simultaneousSelectionFeedback(isEnabled: Bool = true) -> some View {
        simultaneousGesture(TapGesture().onEnded { _ in
            if isEnabled {
                UISelectionFeedbackGenerator().selectionChanged()
            }
        })
    }
}
