//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

// LoadingPresentable.swift (in XUI)
import SwiftUI

private struct LoadingPresentableModifier: ViewModifier {
    @State private var presenter = LoadingPresenter.shared

    func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: $presenter.showLoading) {
                LoadingOverlay()
            }
    }
}

public extension View {
    func loadingPresentable() -> some View {
        modifier(LoadingPresentableModifier())
    }
}
