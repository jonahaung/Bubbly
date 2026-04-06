//
//  CustomButton.swift
//  XUI
//
//  Created by Aung Ko Min on 3/4/26.
//

import SwiftUI

public struct CustomButton<Content: View>: View {

	let label: () -> Content
	let action: () -> Void
	let onFinished: (() -> Void)?
	@State private var buttonIsPressing: Bool = false

	public init(action: @escaping () -> Void, label: @escaping () -> Content, onFinished: (() -> Void)? = nil) {
		self.label = label
		self.action = action
		self.onFinished = onFinished
	}

	public var body: some View {
		label()
			.opacity(buttonIsPressing ? 0.3 : 1.0)
			._onButtonGesture { pressing in
				if pressing {
					buttonIsPressing = true
				} else {
					UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.8)
				}
			} perform: {
				action()
				Task.detached {
					try? await Task.sleep(seconds: 0.5)
					Task { @MainActor in
						buttonIsPressing = false
						onFinished?()
					}
				}
			}
	}
}

