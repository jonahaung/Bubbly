//
//  ViewDebug.swift
//  XUI
//
//  Created by Aung Ko Min on 25/5/26.
//


import SwiftUI

@MainActor
public final class ViewDebug {
    public static var isEnabled = false
}

public extension View {
    @MainActor
    @ViewBuilder
    func viewDebug() -> some View {
        if ViewDebug.isEnabled {
            self.background(Color.random())
        } else {
            self
        }
    }
}

private extension Color {
    static func random(
        in range: ClosedRange<Double> = 0...1,
        randomOpacity: Bool = false
    ) -> Color {
        Color(
            red: .random(in: range),
            green: .random(in: range),
            blue: .random(in: range),
            opacity: randomOpacity ? .random(in: 0...1) : 1
        )
    }
}
