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
            .fullScreenCover(item: $toastPresenter.toast) { toast in
                ToastHolderView(toast: toast)
                    .presentationBackground(.clear)
            }
    }
}

public extension View {
    func toastPresentable() -> some View {
        modifier(ToastPresentableodifier())
    }
}
