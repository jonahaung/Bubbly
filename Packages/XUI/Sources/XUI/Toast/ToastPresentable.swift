//  ToastPresentable.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import SwiftUI

private struct ToastPresentableodifier: ViewModifier {
    @State private var toastPresenter: ToastPresenter = .shared
    @State private var loadingPresenter: LoadingPresenter = .shared
    func body(content: Content) -> some View {
        content
            .ignoresSafeArea(.keyboard)
            .overlay {
                if let toast = toastPresenter.toast {
                    ToastHolderView(toast: toast)
                }
                if loadingPresenter.showLoading {
                    LoadingIndicator(20)
                }
            }
    }
}

public extension View {
    func toastPresentable() -> some View {
        modifier(ToastPresentableodifier())
    }
}
