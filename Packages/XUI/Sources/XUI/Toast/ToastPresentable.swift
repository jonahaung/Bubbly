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
            .overlay {
                if let toast = toastPresenter.toast {
                    ToastHolderView(toast: toast)
                        .transition(.move(edge: toast.style.edge))
                }
            }
    }
}

public extension View {
    func toastPresentable() -> some View {
        modifier(ToastPresentableodifier())
    }
}
