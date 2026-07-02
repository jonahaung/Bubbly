//  Simulative.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import SwiftUI

// MARK: - Simulative

protocol Simulative {
    var impulseCount: Int { get set }

    var initialVelocity: CGFloat { get set }
}

// MARK: - AnySimulativeViewModifier

struct AnySimulativeViewModifier: ViewModifier {
    private var _body: (AnyView) -> AnyView

    init(_ modifier: some ViewModifier & Simulative) {
        _body = { content in
            AnyView(content.modifier(modifier))
        }
    }

    func body(content: Content) -> AnyView {
        _body(AnyView(content))
    }
}

extension ViewModifier where Self: Simulative {
    func eraseToAnySimulativeViewModifier() -> AnySimulativeViewModifier {
        AnySimulativeViewModifier(self)
    }
}
