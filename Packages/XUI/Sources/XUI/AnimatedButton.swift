//
//  AnimatedButton.swift
//  XUI
//
//  Created by Aung Ko Min on 27/1/26.
//

import SwiftUI

public struct AnimatedButton<Label: View>: View {
	let alignment: HorizontalAlignment
	let label: () -> Label
	let action: () -> Void
	@State private var animate = false

	public init(
		_ alignment: HorizontalAlignment,
		action: @escaping () -> Void,
		@ViewBuilder label: @escaping () -> Label
	) {
		self.label = label
		self.action = action
		self.alignment = alignment
	}

	public var body: some View {
		Button {
			withAnimation(
				.interpolatingSpring(
					stiffness: 170,
					damping: 10
				)
			) {
				animate.toggle()
			} completion: {
				withAnimation(.bouncy(extraBounce: 0.4)) {
					animate = false
				} completion: {
					action()
				}
			}
		} label: {
			label()
				.rotationEffect(.degrees(degrees), anchor: anchor)
				.scaleEffect(animate ? 1.8 : 1, anchor: anchor)
				.offset(y: offsetY)
		}
		.buttonStyle(.borderless)
		.sensoryFeedback(.selection, trigger: anchor)
		.geometryGroup()
	}

	private var offsetY: CGFloat {
		CGFloat(animate ? alignment == .center ? -10 : -40 : 0)
	}
	private var degrees: Double {
		if animate {
			switch alignment {
			case .leading: return -45
			case .center: return 360
			case .trailing: return 45
			default: return 0
			}
		}
		return 0
	}
	private var anchor: UnitPoint {
		switch alignment {
		case .leading: return .bottomTrailing
		case .center: return .center
		case .trailing: return .bottomLeading
		default: return .center
		}
	}
}
