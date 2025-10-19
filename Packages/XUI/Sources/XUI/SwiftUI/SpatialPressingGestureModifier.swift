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

	init(action: @escaping (CGPoint?) -> Void) {
		self.onPressingChanged = action
	}

	func body(content: Content) -> some View {
		let gesture = SpatialPressingGesture(location: $currentLocation)

		content
			.gesture(gesture)
			.onChange(of: currentLocation, initial: false) { _, location in
				onPressingChanged(location)
			}
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
	}

	@Binding var location: CGPoint?

	public func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
		Coordinator()
	}

	public func makeUIGestureRecognizer(context: Context) -> UILongPressGestureRecognizer {
		let recognizer = UILongPressGestureRecognizer()
		recognizer.minimumPressDuration = 0.8
		recognizer.delegate = context.coordinator
		return recognizer
	}

	public func handleUIGestureRecognizerAction(
		_ recognizer: UIGestureRecognizerType, context: Context) {
			switch recognizer.state {
			case .began:
				location = context.converter.location(in: .global)
			case .ended, .cancelled, .failed:
				location = nil
			default:
				break
			}
		}
}

public extension View {
	func onPressingChanged(_ action: @escaping (CGPoint?) -> Void) -> some View {
		modifier(SpatialPressingGestureModifier(action: action))
	}
}
