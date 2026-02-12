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
					ModalOverlay(
						toast.style.alignment,
						from: toast.style.edge,
						allowsBackgroundTap: toast.allowsBackgroundTap,
					) {
						toast.node.eraseToNode()
							.lineHeight(.multiple(factor: 1.1))
							.onTapGesture {
								toastPresenter.dismiss()
								toast.action?()
							}
							.padding(16)
							.glassEffect(.regular, in: .containerRelative)
							.runningBorder(lineWidth: 2, cornerRadius: 12)
							.containerShape(RoundedRectangle(cornerRadius: 12))
							.padding(2)
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
