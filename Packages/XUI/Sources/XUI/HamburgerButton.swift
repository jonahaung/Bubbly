//
//  HamburgerButton.swift
//  XUI
//
//  Created by Aung Ko Min on 7/3/26.
//

import SwiftUI

public struct HamburgerButton: View {

	@Binding private var isOpen: Bool

	private let size: CGFloat
	private let color: Color
	private let padding: CGFloat

	private var thickness: CGFloat { (size - padding) * 0.12 }
	private var spacing: CGFloat { (size - padding) * 0.25 }
	private var width: CGFloat { size - padding }
	private var height: CGFloat { thickness * 2 + spacing }

	public init(
		isOpen: Binding<Bool>,
		size: CGFloat = 48,
		color: Color = .accentColor,
		padding: CGFloat = 14
	) {
		self._isOpen = isOpen
		self.size = size
		self.color = color
		self.padding = padding
	}

	public var body: some View {

		let offset = (thickness + spacing) / 2

		Button {
			withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
				isOpen.toggle()
			}
		} label: {
			VStack(spacing: spacing) {
				bar
					.rotationEffect(.degrees(isOpen ? 45 : 0))
					.offset(y: isOpen ? offset : 0)

				bar
					.rotationEffect(.degrees(isOpen ? -45 : 0))
					.offset(y: isOpen ? -offset : 0)

			}
			.frame(width: width, height: height)
			.padding(.vertical, padding)
			.padding(.horizontal, padding/2)
			.contentShape(Rectangle())
		}
		.buttonStyle(.plain)
		
	}

	private var bar: some View {
		RoundedRectangle(cornerRadius: thickness / 2)
			.fill(color)
			.frame(width: width, height: thickness)
	}
}
