//
//  Redactions.swift
//  XUI
//
//  Created by Aung Ko Min on 9/4/26.
//

import SwiftUI

extension RedactionReasons {
	public static let animatedPlaceholder = RedactionReasons(rawValue: 100)
	public static let hidden = RedactionReasons(rawValue: 101)
}

public enum ShapeType {
	case rectangle
	case roundedRectangle(cornerRadius: CGFloat)
	case circle
}

extension View {
	public func redactable(shapeType: ShapeType = .roundedRectangle(cornerRadius: 12)) -> some View
	{
		modifier(Redactable(shapeType: shapeType))
	}
}

private struct AnimatedPlaceholder: ViewModifier {
	let shapeType: ShapeType
	@State var size: CGSize = .zero

	@State private var xOffset: CGFloat = .zero
	private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

	let gradient = Gradient(colors: [Color.appSecondary, .appTertiary, .appSecondary])

	func body(content: Content) -> some View {
		content
			.opacity(.zero)
			.overlay(overlayView)
			.onReceive(timer) { _ in
				if xOffset == size.width {
					xOffset = -size.width
				} else {
					withAnimation(.linear(duration: 1)) {
						xOffset = size.width
					}
				}
			}
			.overlay(
				ZStack {
					GeometryReader { geometry in
						Color.clear
							.onAppear {
								size = geometry.size
							}
					}
				}
			)
	}

	@ViewBuilder
	var overlayView: some View {
		switch shapeType {
		case .rectangle:
			addAnimationContainer { Rectangle() }
		case .roundedRectangle(let cornerRadius):
			addAnimationContainer { RoundedRectangle(cornerRadius: cornerRadius) }
		case .circle:
			addAnimationContainer { Circle() }
		}
	}

	@ViewBuilder
	func addAnimationContainer<Content: Shape>(content: () -> Content) -> some View {
		ZStack {
			content()
				.fill(Color.appSecondary)

			Rectangle()
				.fill(
					LinearGradient(
						gradient: gradient,
						startPoint: .leading,
						endPoint: .trailing
					)
				)
				.offset(x: xOffset)
		}
		.clipShape(content())
	}
}

private struct Redactable: ViewModifier {
	@Environment(\.redactionReasons) private var reasons

	let shapeType: ShapeType

	@ViewBuilder
	func body(content: Content) -> some View {
		switch reasons {
		case .animatedPlaceholder:
			content
				.modifier(AnimatedPlaceholder(shapeType: shapeType))
		case .hidden:
			content
				.hidden()
		default:
			content
		}
	}
}
