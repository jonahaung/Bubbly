//  AnyContinuousEffect.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import SwiftUI

@MainActor
struct AnyContinuousEffect {
    private var _viewModifier: (Bool) -> AnyContinuousViewModifier

    static func modifier(_ modifier: @escaping (Bool) -> some ViewModifier & Continuous) -> Self {
        AnyContinuousEffect(_viewModifier: { isActive in
            modifier(isActive).eraseToAnyContinuousViewModifier()
        })
    }

    func viewModifier(_ isActive: Bool) -> AnyContinuousViewModifier {
        _viewModifier(isActive)
    }
}

@MainActor
struct AnyContinuousViewModifier: ViewModifier {
    private var _body: (AnyView) -> AnyView

    init(_ modifier: some ViewModifier & Continuous) {
        _body = { content in
            AnyView(content.modifier(modifier))
        }
    }

    func body(content: Content) -> AnyView {
        _body(AnyView(content))
    }
}

@MainActor
extension ViewModifier where Self: Continuous {
    func eraseToAnyContinuousViewModifier() -> AnyContinuousViewModifier {
        AnyContinuousViewModifier(self)
    }
}

@MainActor
protocol Continuous {
    var isActive: Bool { get }
}
