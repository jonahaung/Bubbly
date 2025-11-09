//
//  TransitionSourceModifier.swift
//  XUI
//
//  Created by Aung Ko Min on 23/9/24.
//

import SwiftUI

private struct TransitionSourceModifier: ViewModifier {
    let id: AnyHashable
    let namespace: Namespace.ID
    func body(content: Content) -> some View {
        content
            .matchedTransitionSource(id: id, in: namespace) { src in
                src
            }
            .buttonStyle(.plain)
    }
}

public extension View {
    func transitionSource(id: AnyHashable, namespace: Namespace.ID) -> some View {
        modifier(TransitionSourceModifier(id: id, namespace: namespace))
    }
}
