//  AnyAnimatableViewModifier.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import SwiftUI

@MainActor
struct AnyAnimatableViewModifier: ViewModifier, Animatable {
    private var _body: (Content) -> AnyView

    var animatableData: EmptyAnimatableData

    init(_ modifier: some ViewModifier & Animatable) {
        _body = { content in
            AnyView(content.modifier(modifier))
        }
        animatableData = .zero
    }

    func body(content: Content) -> AnyView {
        _body(content)
    }
}

@MainActor
extension ViewModifier where Self: Animatable {
    func eraseToAnyAnimatableViewModifier() -> AnyAnimatableViewModifier {
        AnyAnimatableViewModifier(self)
    }
}
