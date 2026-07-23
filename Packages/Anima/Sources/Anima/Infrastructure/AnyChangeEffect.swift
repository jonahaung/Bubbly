//  AnyChangeEffect.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import SwiftUI

/// A type-erased change effect.
@MainActor
public struct AnyChangeEffect {
    private var modifier: (Int) -> AnyViewModifier

    private var animation: Animation?

    var cooldown: Double

    var delay: Double = 0

    fileprivate init(modifier: @escaping (Int) -> AnyViewModifier, animation: Animation?, cooldown: Double) {
        self.modifier = modifier
        self.animation = animation
        self.cooldown = cooldown
    }

    func viewModifier(changeCount: Int) -> some ViewModifier {
        modifier(changeCount)
            .animation(animation)
    }

    public func delay(_ delay: Double) -> Self {
        var copy = self
        copy.delay = delay

        return copy
    }
}

@MainActor
extension AnyChangeEffect {
    static func animation(_ makeModifier: @escaping (Int) -> some ViewModifier & Animatable, animation: Animation? = .default, cooldown: Double = 0.33) -> AnyChangeEffect {
        AnyChangeEffect(
            modifier: { change in
                makeModifier(change)
                    .eraseToAnyViewModifier()
            },
            animation: animation,
            cooldown: cooldown
        )
    }

    static func simulation(_ makeModifier: @escaping (Int) -> some ViewModifier & Simulative) -> AnyChangeEffect {
        AnyChangeEffect(modifier: { change in
            makeModifier(change).eraseToAnyViewModifier()
        }, animation: nil, cooldown: 0.0)
    }
}
