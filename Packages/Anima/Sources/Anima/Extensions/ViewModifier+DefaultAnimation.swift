//  ViewModifier+DefaultAnimation.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import SwiftUI

@MainActor
extension ViewModifier where Self: Animatable {
    func defaultAnimation(_ animation: Animation) -> some ViewModifier {
        transaction { t in
            if t.animation == .default {
                t.animation = animation
            }
        }
    }
}
