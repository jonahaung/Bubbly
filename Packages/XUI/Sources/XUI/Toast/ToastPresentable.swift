//
//  ToastPresentable.swift
//  XUI
//
//  Created by Aung Ko Min on 18/10/25.
//

import SwiftUI

private struct ToastPresentableodifier: ViewModifier {
	@State private var toastPresenter = ToastPresenter.shared
	public func body(content: Content) -> some View {
		ZStack(alignment: .top) {
			content
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
