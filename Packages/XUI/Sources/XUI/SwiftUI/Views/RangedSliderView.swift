//
//  RangedSliderView.swift
//
//
//  Created by Aung Ko Min on 29/7/23.
//

import SwiftUI

public struct RangedSliderView: View {
    @Binding var x1: CGFloat
    @Binding var x2: CGFloat

    @State private var inactiveColor: Color
    @State private var activeColor: Color
    @State private var barheight: CGFloat
    @State private var buttonDiameter: CGFloat
    @State private var pos1: CGFloat
    @State private var pos2: CGFloat
    @State private var shoutOutText: String?

    private let scale: CGFloat
    private let offset: CGFloat
    private var widthFactor: CGFloat { pos2 - pos1 }
    private var step: Int { scale.int / 20 }

    public init(
        inactiveColor: Color = Color.quaternaryLabel,
        activeColor: Color = .green,
        barheight: CGFloat = 4,
        buttonDiameter: CGFloat = 33,
        x1: Binding<CGFloat>,
        x2: Binding<CGFloat>,
        scale: CGFloat,
        offset: CGFloat
    ) {
        self.inactiveColor = inactiveColor
        self.activeColor = activeColor
        self.barheight = barheight
        self.buttonDiameter = buttonDiameter
        _x1 = x1
        _x2 = x2
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
                    Text("\(x1.int) - \(x2.int)")
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
                        .frame(width: geometry.size.width * widthFactor, height: barheight, alignment: .center)
                        .position(x: geometry.size.width * (pos1 + (widthFactor / 2.0)), y: yCenter)

                    // Buttons here
                    Circle()
                        .foregroundStyle(activeColor.gradient)
                        .frame(width: buttonDiameter, height: buttonDiameter, alignment: .trailing)
                        .position(x: geometry.size.width * pos1, y: yCenter)
                        .offset(x: buttonDiameter / 2)
                        .gesture(DragGesture()
                            .onChanged { value in
                                // Caluclate the scaled position
                                let newPos = value.location.x / geometry.size.width
                                // Set new Position
                                if newPos < 0 { pos1 = 0 } else if newPos >= pos2 { pos1 = pos2 - 0.01 } else { pos1 = newPos }
                                let value = (pos1.scaled(by: scale) + offset)
                                let rounded = ((value.int / step) * step).cgFloat
                                x1 = rounded
                                shoutOutText = rounded.formatted()
                            }.onEnded { _ in
                                shoutOutText = nil
                            }
                        )

                    Circle()
                        .foregroundStyle(activeColor.gradient)
                        .frame(width: buttonDiameter, height: buttonDiameter, alignment: .leading)
                        .position(x: geometry.size.width * pos2, y: yCenter)
                        .offset(x: -(buttonDiameter / 2))
                        .gesture(DragGesture()
                            .onChanged { value in
                                let newPos = value.location.x / geometry.size.width
                                if newPos > 1.0 { pos2 = 1.0 } else if newPos <= pos1 { pos2 = pos1 + 0.01 } else { pos2 = newPos }
                                let value = pos2.scaled(by: scale) + offset
                                let rounded = ((value.int / step) * step).cgFloat
                                x2 = rounded
                                shoutOutText = rounded.formatted()
                            }.onEnded { _ in
                                shoutOutText = nil
                            }
                        )
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

//
// public struct RangedSliderView: View {
//    enum Constants {
//        static let thumbSize = CGFloat(30)
//    }
//    @Binding private var originalValue: ClosedRange<Int>
//    @State private var currentValue: ClosedRange<Int>
//    private let sliderBounds: ClosedRange<Int>
//    private let step: Float
//    private let formatter = KMBFormatter()
//
//    @State private var isLowerActive = false
//    @State private var isUpperActive = false
//
//    public init(value: Binding<ClosedRange<Int>>, bounds: ClosedRange<Int>, step: Float) {
//        self._originalValue = value
//        self.currentValue = value.wrappedValue
//        self.sliderBounds = bounds
//        self.step = step
//    }
//
//    public var body: some View {
//        VStack(spacing: 1) {
//            Color.clear
//                .frame(height: 25)
//            GeometryReader { geomentry in
//                sliderView(sliderSize: geomentry.size)
//            }
//        }
//        .padding(.trailing, Constants.thumbSize/2)
//        ._flexible(.horizontal)
//        .padding(.horizontal)
//        .onChange(of: originalValue) { oldValue, newValue in
//            if currentValue != originalValue {
//                currentValue = originalValue
//            }
//        }
//    }
//
//    @ViewBuilder private func sliderView(sliderSize: CGSize) -> some View {
//        let sliderViewYCenter = sliderSize.height / 2
//        ZStack {
//            let sliderBoundDifference = sliderBounds.count
//            let stepWidthInPixel = CGFloat(sliderSize.width) / CGFloat(sliderBoundDifference)
//
//            let leftThumbLocation: CGFloat = currentValue.lowerBound == (sliderBounds.lowerBound)
//            ? 0
//            : CGFloat(Float(currentValue.lowerBound - sliderBounds.lowerBound)) * stepWidthInPixel
//
//            let rightThumbLocation = CGFloat(currentValue.upperBound) * stepWidthInPixel
//            lineBetweenThumbs(from: .init(x: leftThumbLocation, y: sliderViewYCenter), to: .init(x: rightThumbLocation, y: sliderViewYCenter))
//
//            let leftThumbPoint = CGPoint(x: leftThumbLocation, y: sliderViewYCenter)
//            thumbView(position: leftThumbPoint, value: Float(currentValue.lowerBound))
//                .highPriorityGesture(
//                    DragGesture()
//                        .onChanged { dragValue in
//                            let dragLocation = dragValue.location
//                            let xThumbOffset = min(max(0, dragLocation.x), sliderSize.width + Constants.thumbSize/2)
//
//                            let newValue = Float(sliderBounds.lowerBound) + Float(xThumbOffset / stepWidthInPixel)
//
//                            let rounded = ((newValue / step) * step).int
//                            // Stop the range thumbs from colliding each other
//                            if rounded < currentValue.upperBound {
//                                isLowerActive = true
//                                currentValue = rounded...currentValue.upperBound
//                                if rounded != 0 && rounded % 5 == 0 { // Prevent repeated vibration
//                                    _Haptics.play(.soft)
//                                }
//                            }
//                        }.onEnded { value in
//                            isLowerActive = false
//                            updateValue()
//                        }
//                )
//                .foregroundStyle(isLowerActive ? .primary : .tertiary)
//
//            thumbView(position: CGPoint(x: rightThumbLocation, y: sliderViewYCenter), value: Float(currentValue.upperBound))
//                .highPriorityGesture(
//                    DragGesture()
//                        .onChanged { dragValue in
//                            let dragLocation = dragValue.location
//                            let xThumbOffset = min(max(CGFloat(leftThumbLocation), dragLocation.x), sliderSize.width + Constants.thumbSize)
//
//                            var newValue = Float(xThumbOffset / stepWidthInPixel) // convert back the value bound
//                            newValue = min(newValue, Float(sliderBounds.upperBound))
//
//                            let rounded = ((newValue / step) * step).int
//                            // Stop the range thumbs from colliding each other
//                            if rounded > currentValue.lowerBound {
//                                isUpperActive = true
//                                currentValue = currentValue.lowerBound...rounded
//                                if rounded % 5 == 0 {
//                                    _Haptics.play(.soft)
//                                }
//                            }
//                        } .onEnded {_ in
//                            isUpperActive = false
//                            updateValue()
//                        }
//                )
//                .foregroundStyle(isUpperActive ? .primary : .tertiary)
//        }
//    }
//
//    @ViewBuilder private func lineBetweenThumbs(from: CGPoint, to: CGPoint) -> some View {
//        Path { path in
//            path.move(to: from)
//            path.addLine(to: to)
//        }
//        .stroke(Color.green,lineWidth: 5)
//    }
//
//    @ViewBuilder private func thumbView(position: CGPoint, value: Float) -> some View {
//        ZStack {
//            Text(formatter.string(fromNumber: Int(value)))
//                .font(isLowerActive || isUpperActive ? .title : .footnote.bold().italic())
//                .offset(
//                    x: Int(value) == self.currentValue.lowerBound ? Constants.thumbSize : Int(value) == currentValue.upperBound ? -Constants.thumbSize : 0,
//                    y: isLowerActive || isUpperActive ? -35 : -23
//                )
//
//            Circle()
//                .frame(width: 30, height: 30)
//                .foregroundStyle( isValid(Int(value)) ? Color.green.gradient : Color.systemBackground.gradient)
//                .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 0)
//                .contentShape(Circle())
//        }
//        .position(x: position.x, y: position.y)
//        .compositingGroup()
//    }
//
//    private func isValid(_ value: Int) -> Bool {
//        value != sliderBounds.lowerBound && value != sliderBounds.upperBound
//    }
//
//    private func updateValue() {
//        originalValue = currentValue
//        _Haptics.play(.rigid)
//    }
// }
