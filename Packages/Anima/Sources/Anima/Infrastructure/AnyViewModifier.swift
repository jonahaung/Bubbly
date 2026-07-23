//  AnyViewModifier.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import SwiftUI

@MainActor
struct AnyViewModifier: ViewModifier {
    private var _body: (Content) -> AnyView

    init(_ modifier: some ViewModifier) {
        _body = { content in
            AnyView(content.modifier(modifier))
        }
    }

    func body(content: Content) -> AnyView {
        _body(content)
    }
}

@MainActor
extension ViewModifier {
    func eraseToAnyViewModifier() -> AnyViewModifier {
        AnyViewModifier(self)
    }
}
