//  SplashView.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import SwiftUI

private struct SplashView<SplashContent: View>: ViewModifier {
    private let timeout: TimeInterval
    private let splashContent: () -> SplashContent

    @State private var isActive = true

    init(timeout: TimeInterval, @ViewBuilder splashContent: @escaping () -> SplashContent) {
        self.timeout = timeout
        self.splashContent = splashContent
    }

    func body(content: Content) -> some View {
        if isActive {
            splashContent()
                .task {
                    do {
                        try await Task.sleep(for: .seconds(timeout))
                        isActive = false
                    } catch {
                        log(error)
                    }
                }
        } else {
            content
        }
    }
}

public extension View {
    func splashView(
        timeout: TimeInterval = 2.5,
        @ViewBuilder splashContent: @escaping () -> some View
    ) -> some View {
        modifier(SplashView(timeout: timeout, splashContent: splashContent))
    }
}
