//
//  SpatialPressingGestureModifier.swift
//  XUI
//
//  Created by Aung Ko Min on 12/9/25.
//

import SwiftUI

struct SpatialPressingGestureModifier: ViewModifier {
	var onPressingChanged: (CGPoint?) -> Void

	@State var currentLocation: CGPoint?
	let coordinateSpace: CoordinateSpace

	init(coordinateSpace: CoordinateSpace, action: @escaping (CGPoint?) -> Void) {
		self.onPressingChanged = action
		self.coordinateSpace = coordinateSpace
	}

	func body(content: Content) -> some View {
		let gesture = SpatialPressingGesture(location: $currentLocation, coordinateSpace: coordinateSpace)
		content
			.gesture(gesture)
			.onChange(of: currentLocation, { oldValue, newValue in
				if let newValue {
					onPressingChanged(newValue)
				}
			})
	}
}

public struct SpatialPressingGesture: UIGestureRecognizerRepresentable {
	public final class Coordinator: NSObject, UIGestureRecognizerDelegate {
		@objc
		public func gestureRecognizer(
			_ gestureRecognizer: UIGestureRecognizer,
			shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer
		) -> Bool {
			false
		}
		public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
			true
		}
	}

	@Binding var location: CGPoint?
	let coordinateSpace: CoordinateSpace

	public func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
		Coordinator()
	}

	public func makeUIGestureRecognizer(context: Context) -> UILongPressGestureRecognizer {
		let recognizer = UILongPressGestureRecognizer()
		recognizer.minimumPressDuration = 0.5
		recognizer.delegate = context.coordinator
		return recognizer
	}

	public func handleUIGestureRecognizerAction(
		_ recognizer: UIGestureRecognizerType, context: Context) {
			switch recognizer.state {
			case .began:
				location = context.converter.location(in: .global)
			case .ended:
				break
			case .cancelled, .failed:
				location = nil
			default:
				break
			}
		}
}

public extension View {
	func onPressingChanged(in coordinateSpace: CoordinateSpace, _ action: @escaping (CGPoint?) -> Void) -> some View {
		modifier(SpatialPressingGestureModifier(coordinateSpace: coordinateSpace, action: action))
	}
}
