//
//  ToastBanner.swift
//  XUI
//
//  Created by Aung Ko Min on 18/10/25.
//

import SwiftUI

public struct ToastBanner: View {

	@Bindable private var presenter: ToastPresenter = .shared
	@State private var offsetY: CGFloat = -300
	let toast: Toast

	public init(toast: Toast) {
		self.toast = toast
	}

	public var body: some View {
		ZStack(alignment: .center) {
			Text(.init(toast.message))
				.font(.callout)
				.padding(.horizontal)
				.padding(.vertical, 8)
		}
		.background {
			RoundedRectangle(cornerRadius: 12)
				.fill(Color.systemBackground)
				.glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
				.runningBorder()
		}
		.padding(.horizontal)
		.flexible(.horizontal)
		.allowsHitTesting(presenter.toast != nil)
		.statusBarHidden()
		.offset(y: offsetY)
		.onAppear {
			withAnimation(.easeOut.delay(1)) {
				offsetY = 0
			}
		}
		.onTapGesture {
			if let action = toast.action {
				action()
			}
			presenter.dismiss()
		}
	}
}
