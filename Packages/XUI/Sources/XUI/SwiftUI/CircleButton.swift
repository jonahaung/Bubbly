//
//  CircleButton.swift
//  XUI
//
//  Created by Aung Ko Min on 20/9/25.
//

import SwiftUI
import SFSafeSymbols

// MARK: - Model
public struct CircleButton: View {

	public let symbol: SFSymbol
	private let size: CGFloat
	public let color: Color
	public let action: () -> Void

	public init(
		_ symbol: SFSymbol,
		_ size: CGFloat = 35,
		color: Color = .accentColor,
		action: @escaping () -> Void
	) {
		self.symbol = symbol
		self.size = size
		self.color = color
		self.action = action
	}

	public var body: some View {
		Button {
			action()
		} label: {
			ZStack {
				Circle().fill(Color.white.gradient)
					.frame(square: size)
					.layoutPriority(1)
				SystemImage(symbol, size*0.4)
					.foregroundStyle(color.gradient)
					.fontWeight(.semibold)
			}
		}
		.buttonRepeatBehavior(.disabled)
		.buttonStyle(.borderless)
	}
}
