//
//  RangedSliderView.swift
//
//
//  Created by Aung Ko Min on 29/7/23.
//

import SwiftUI

public struct RangedSliderView: View {
	@Binding var lowerValue: CGFloat
	@Binding var upperValue: CGFloat

	@State private var inactiveColor: Color
	@State private var activeColor: Color
	@State private var barheight: CGFloat
	@State private var buttonDiameter: CGFloat
	@State private var pos1: CGFloat
	@State private var pos2: CGFloat
	@State private var shoutOutText: String?

	private let scale: CGFloat
	private let offset: CGFloat
	private var widthFactor: CGFloat {
		pos2 - pos1
	}

	private var step: Int {
		scale.int / 20
	}

	public init(inactiveColor: Color = Color.quaternaryLabel,
	            activeColor: Color = .green,
	            barheight: CGFloat = 4,
	            buttonDiameter: CGFloat = 33,
	            x1: Binding<CGFloat>,
	            x2: Binding<CGFloat>,
	            scale: CGFloat,
	            offset: CGFloat)
	{
		self.inactiveColor = inactiveColor
		self.activeColor = activeColor
		self.barheight = barheight
		self.buttonDiameter = buttonDiameter
		_lowerValue = x1
		_upperValue = x2
		pos1 = (x1.wrappedValue - offset) / scale
		pos2 = (x2.wrappedValue - offset) / scale
		self.scale = scale
		self.offset = offset
	}

	public var body: some View {
		VStack(spacing: 0) {
			ZStack(alignment: .bottom) {
				if let shoutOutText {
					Text(shoutOutText)
						.font(.title.weight(.semibold).width(.condensed))
				} else {
					Text("\(lowerValue.int) - \(upperValue.int)")
						.font(.footnote.weight(.semibold).width(.compressed))
				}
			}
			.frame(height: 35)
			ZStack {
				GeometryReader { geometry in
					let yCenter = buttonDiameter / 2.0
					let xCenter = geometry.size.width / 2
					// Background here

					RoundedRectangle(cornerRadius: barheight / 2)
						.foregroundStyle(inactiveColor.gradient)
						.frame(width: nil, height: barheight, alignment: .center)
						.position(x: xCenter, y: yCenter)

					// Active Overlay here
					Rectangle()
						.foregroundStyle(activeColor.gradient)
						.frame(
							width: geometry.size.width * widthFactor,
							height: barheight,
							alignment: .center
						)
						.position(x: geometry.size.width * (pos1 + (widthFactor / 2.0)), y: yCenter)

					// Buttons here
					Circle()
						.foregroundStyle(activeColor.gradient)
						.frame(width: buttonDiameter, height: buttonDiameter, alignment: .trailing)
						.position(x: geometry.size.width * pos1, y: yCenter)
						.offset(x: buttonDiameter / 2)
						.gesture(DragGesture()
							.onChanged { value in
								// Calculate the scaled position
								let newPos = value.location.x / geometry.size.width
								// Set new Position
								if newPos < 0 {
									pos1 = 0
								} else if newPos >= pos2 {
									pos1 = pos2 - 0.01
								} else {
									pos1 = newPos
								}
								let scaledValue = (pos1.scaled(by: scale) + offset)
								let rounded = ((scaledValue.int / step) * step).cgFloat
								lowerValue = rounded
								shoutOutText = rounded.formatted()
							}.onEnded { _ in
								shoutOutText = nil
							})

					Circle()
						.foregroundStyle(activeColor.gradient)
						.frame(width: buttonDiameter, height: buttonDiameter, alignment: .leading)
						.position(x: geometry.size.width * pos2, y: yCenter)
						.offset(x: -(buttonDiameter / 2))
						.gesture(DragGesture()
							.onChanged { value in
								let newPos = value.location.x / geometry.size.width
								if newPos > 1.0 {
									pos2 = 1.0
								} else if newPos <= pos1 {
									pos2 = pos1 + 0.01
								} else {
									pos2 = newPos
								}
								let scaledValue = pos2.scaled(by: scale) + offset
								let rounded = ((scaledValue.int / step) * step).cgFloat
								upperValue = rounded
								shoutOutText = rounded.formatted()
							}.onEnded { _ in
								shoutOutText = nil
							})
				}
			}
			.frame(height: buttonDiameter)
			HStack(alignment: .bottom) {
				Text(offset, format: .number)
					.bold()
				Spacer()
				Text(offset + scale, format: .number)
					.bold()
			}
			.font(.caption.width(.condensed).weight(.medium))
			.foregroundStyle(.secondary)
		}
	}
}
