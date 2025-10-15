//
//  SplashView.swift
//  HomeForYou
//
//  Created by Aung Ko Min on 24/4/23.
//

import SwiftUI

private struct SplashView<SplashContent: View>: ViewModifier {

    private let timeout: TimeInterval
    private let splashContent: () -> SplashContent

    @State private var isActive = true

    public init(timeout: TimeInterval, @ViewBuilder splashContent: @escaping () -> SplashContent) {
        self.timeout = timeout
        self.splashContent = splashContent
    }

    public func body(content: Content) -> some View {
        if isActive {
            splashContent()
                .task {
                    do {
                        try await Task.sleep(for: .seconds(timeout))
                        isActive = false
                    } catch {
                        Log(error)
                    }
                }
        } else {
            content
        }
    }
}

public extension View {
    func splashView<SplashContent: View>(timeout: TimeInterval = 2.5, @ViewBuilder splashContent: @escaping () -> SplashContent) -> some View {
        modifier(SplashView(timeout: timeout, splashContent: splashContent))
    }
}
