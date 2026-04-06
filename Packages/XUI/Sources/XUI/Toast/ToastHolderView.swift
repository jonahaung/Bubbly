//
//  ToastHolderView.swift
//  XUI
//
//  Created by Aung Ko Min on 1/4/26.
//

import SwiftUI

struct ToastHolderView: View {
	let toast: Toast
	@State private var isPressing: Bool = false
    var body: some View {
		ModalOverlay(
			toast.style.alignment,
			from: toast.style.edge,
			allowsBackgroundTap: toast.allowsBackgroundTap
		) {
			toast.node.eraseToNode()
				.lineHeight(.multiple(factor: 1.1))
				.opacity(isPressing ? 0.3 : 1)
				.sensoryFeedback(.selection, trigger: isPressing, condition: { oldValue, newValue in
					oldValue == false && newValue == true
				})
				.padding(16)
				.glassEffect(.regular, in: .containerRelative)
				.runningBorder(lineWidth: 2, cornerRadius: 12)
				.containerShape(RoundedRectangle(cornerRadius: 12))
				.padding(.horizontal, 4)
				._onButtonGesture(pressing: { pressing in
					isPressing = pressing
				}, perform: {
					toast.action?()
					ToastPresenter.shared.dismiss()
				})
		} onClose: {
			ToastPresenter.shared.dismiss()
		}
    }
}
