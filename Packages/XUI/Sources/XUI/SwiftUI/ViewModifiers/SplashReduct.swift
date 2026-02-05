//
//  SplashReduct.swift
//  HomeForYou
//
//  Created by Aung Ko Min on 24/4/23.
//

import SwiftUI

private struct SplashReductView: ViewModifier {
    private let timeout: TimeInterval
    @State private var isActive = true

    init(timeout: TimeInterval) {
        self.timeout = timeout
    }

    func body(content: Content) -> some View {
        content
            .redacted(reason: isActive ? .privacy : [])
            .animation(.interactiveSpring(), value: isActive == true)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
                    isActive = false
                }
            }
            .onDisappear {
                isActive = true
            }
    }
}

public extension View {
    // New lint-compliant name
    func splashReduct(timeout: TimeInterval = 0.3) -> some View {
        modifier(SplashReductView(timeout: timeout))
    }

    // Deprecated shim to preserve old callers
    @available(*, deprecated, renamed: "splashReduct(timeout:)")
    func _splashReduct(for timeout: TimeInterval = 0.3) -> some View {
        splashReduct(timeout: timeout)
    }
}
