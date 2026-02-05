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
			.statusBarHidden(toastPresenter.toast?.style.edge == .top)
			.overlay {
				if let toast = toastPresenter.toast {
					ModalOverlay(toast.style.alignment, from: toast.style.edge) {
						toast.node.eraseToNode()
							.padding()
							.foregroundStyle(Color.label.headroom(4))
							.runningBorder(lineWidth: 1)
							.containerShape(RoundedRectangle(cornerRadius: 12))
					} onClose: {
						toastPresenter.dismiss()
					}
				}
			}
	}
}

public extension View {
	func toastPresentable() -> some View {
		modifier(ToastPresentableodifier())
	}
}
