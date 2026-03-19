//
//  AutoVisualizer.swift
//  XUI
//
//  Created by Aung Ko Min on 14/3/26.
//

import Combine
import SwiftUI

extension View {

	/// Conditionally visualizes touches on the view.
	///
	/// Only touches that hit test with the view are visualized. In order to
	/// enable hit testing on otherwise empty parts of the view, it might be
	/// necessary to configure the ``contentShape(_:)`` of the view
	///
	///     HStack {
	///         Text("Leading")
	///         Spacer()
	///         Text("Trailing")
	///     }
	///     .contentShape(.rect)
	///     .visualizeTouches()
	///
	///
	/// - Parameter isEnabled: If `true`, touches on this view are visualized.
	/// - Returns: A view that visualizes touches.
	public func visualizeTouches(_ isEnabled: Bool) -> some View {
		modifier(TouchVisualizer(isEnabled: isEnabled))
	}

	/// Visualizes touches on the view during screen recording, screen mirroring
	/// or any time in the iOS Simulator.
	///
	/// Only touches that hit test with the view are visualized. In order to
	/// enable hit testing on otherwise empty parts of the view, it might be
	/// necessary to configure the ``contentShape(_:)`` of the view
	///
	///     HStack {
	///         Text("Leading")
	///         Spacer()
	///         Text("Trailing")
	///     }
	///     .contentShape(.rect)
	///     .visualizeTouches()
	///
	/// - Returns: A view that visualizes all touches.
	public func visualizeTouches() -> some View {
		modifier(AutoVisualizer())
	}
}

private struct AutoVisualizer: ViewModifier {
	@State var cancellable: AnyCancellable?

	@State var isCaptured: Bool = false

	func body(content: Content) -> some View {
		content
			#if targetEnvironment(simulator)
				.visualizeTouches(true)
			#else
				.visualizeTouches(isCaptured)
				.onAppear {
					isCaptured = UIScreen.main.isCaptured

					cancellable = NotificationCenter.default
					.publisher(for: UIScreen.capturedDidChangeNotification)
					.sink { notification in
						guard let screen = notification.object as? UIScreen else {
							return
						}

						isCaptured = screen.isCaptured
					}
				}
				.onDisappear {
					cancellable = nil
				}
			#endif
	}
}

private struct TouchVisualizer: ViewModifier {
	struct Touch: Identifiable {
		var id: Int

		var coordinates: CGPoint
	}

	@State var touches: [Touch] = []

	var isEnabled: Bool

	func body(content: Content) -> some View {
		content
			.gesture(TouchVisualizerGesture(isEnabled: isEnabled, touches: $touches))
			.overlay {
				ForEach(isEnabled ? touches : []) { touch in
					TouchView()
						.position(touch.coordinates)
				}
				.accessibilityHidden(true)
				.allowsHitTesting(false)
			}
	}
}

private struct TouchView: View {
	var body: some View {
		Image(systemSymbol: .touchid)
			.resizable()
			.scaledToFit()
			.frame(square: 44)
			.symbolRenderingMode(.hierarchical)
			.environment(\.colorScheme, .light)
	}
}

private struct TouchVisualizerGesture: UIGestureRecognizerRepresentable {
	final class Recognizer: UIGestureRecognizer {
		var touches = 0

		override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
			super.touchesBegan(touches, with: event)

			self.touches += touches.count

			if self.touches >= 0 {
				self.state = .changed
			}
		}

		override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
			if self.touches >= 0 {
				self.state = .changed
			}
		}

		override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
			super.touchesEnded(touches, with: event)

			self.touches -= touches.count

			if self.touches == 0 {
				self.state = .ended
			}
		}

		override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
			super.touchesCancelled(touches, with: event)

			self.touches -= touches.count

			if self.touches == 0 {
				self.state = .cancelled
			}
		}
	}

	final class Coordinator: NSObject, UIGestureRecognizerDelegate {
		func gestureRecognizer(
			_: UIGestureRecognizer,
			shouldRecognizeSimultaneouslyWith _: UIGestureRecognizer
		) -> Bool {
			true
		}
	}

	var isEnabled: Bool

	@Binding var touches: [TouchVisualizer.Touch]

	func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
		Coordinator()
	}

	func makeUIGestureRecognizer(context: Context) -> UIGestureRecognizer {
		let g = Recognizer()
		g.cancelsTouchesInView = false
		g.delegate = context.coordinator

		return g
	}

	func handleUIGestureRecognizerAction(
		_ recognizer: Self.UIGestureRecognizerType,
		context: Self.Context
	) {
		guard isEnabled else { return }
		switch recognizer.state {
		case .began, .changed:
			touches = (0..<recognizer.numberOfTouches).map { i in
				let globalPoint = recognizer.location(ofTouch: i, in: nil)
				let point = context.converter.convert(globalPoint: globalPoint)

				return TouchVisualizer.Touch(id: i, coordinates: point)
			}
		default:
			touches = []
		}
	}
}
