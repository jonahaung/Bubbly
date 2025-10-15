//
//  Modifiers.swift
//  Msgr
//
//  Created by Aung Ko Min on 10/12/22.
//

import SwiftUI

public struct RoundedBorderModifier: ViewModifier {

    private var cornerRadius: CGFloat = 18

    init(cornerRadius: CGFloat) {
        self.cornerRadius = cornerRadius
    }

    public func body(content: Content) -> some View {
        content.overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color.gray.opacity(0.4), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

extension View {
    public func roundWithBorder(cornerRadius: CGFloat = 18) -> some View {
        modifier(RoundedBorderModifier(cornerRadius: cornerRadius))
    }
}
