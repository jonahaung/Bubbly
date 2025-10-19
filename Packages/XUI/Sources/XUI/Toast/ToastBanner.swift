//
//  ToastBanner.swift
//  XUI
//
//  Created by Aung Ko Min on 18/10/25.
//

import SwiftUI

public struct ToastBanner: View {

	@Bindable private var presenter: ToastPresenter = .shared
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
				.glassEffect(.regular.tint(.systemBackground).interactive(), in: RoundedRectangle(cornerRadius: 10))
				.runningBorder()
				.padding(.horizontal)
				.transition(.move(edge: .top))
				.onTapGesture {
					if let action = toast.action {
						action()
					}
					presenter.dismiss()
				}
		}
		.flexible(.horizontal)
		.allowsHitTesting(presenter.toast != nil)
		.statusBarHidden()
	}
}
