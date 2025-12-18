//
//  ToastPresentable.swift
//  XUI
//
//  Created by Aung Ko Min on 18/10/25.
//

import SwiftUI

private struct ToastPresentableodifier: ViewModifier {
    @State private var toastPresenter = ToastPresenter.shared
    func body(content: Content) -> some View {
		content
			.overlay(alignment: .top) {
				if let toast = toastPresenter.toast {
					ToastBanner(toast: toast)
				}
			}
    }
}

public extension View {
    func toastPresentable() -> some View {
        modifier(ToastPresentableodifier())
    }
}
