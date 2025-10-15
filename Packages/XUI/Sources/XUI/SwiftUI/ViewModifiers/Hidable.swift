//
//  Hidable.swift
//  HomeForYou
//
//  Created by Aung Ko Min on 19/5/23.
//

import SwiftUI

private struct HidableModifier: ViewModifier {
    @Binding var isHidden: Bool
    public func body(content: Content) -> some View {
        isHidden ? nil : content.transition(.opacity.animation(.easeInOut(duration: 0.3)))
    }
}

public extension View {
    func _hidable(_ isHidden: Bool) -> some View {
        modifier(HidableModifier(isHidden: .constant(isHidden)))
    }
}
