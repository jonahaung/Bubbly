//
//  SpatialPressingGestureModifier.swift
//  XUI
//
//  Created by Aung Ko Min on 12/9/25.
//

import SwiftUI

struct SpatialPressingGestureModifier: ViewModifier {
    // UI callbacks should be main-actor isolated; do not require @Sendable.
    let onPressingChanged: @MainActor (CGPoint?) -> Void
    let coordinateSpace: CoordinateSpaceProtocol
    let minimumPressDuration: TimeInterval
    let allowableMovement: CGFloat

    init(coordinateSpace: CoordinateSpaceProtocol,
         minimumPressDuration: TimeInterval,
         allowableMovement: CGFloat,
         action: @escaping @MainActor (CGPoint?) -> Void) {
        onPressingChanged = action
        self.coordinateSpace = coordinateSpace
        self.minimumPressDuration = minimumPressDuration
        self.allowableMovement = allowableMovement
    }

    func body(content: Content) -> some View {
        let gesture = SpatialPressingGesture(
            coordinateSpace: coordinateSpace,
            minimumPressDuration: minimumPressDuration,
            allowableMovement: allowableMovement,
            onChange: onPressingChanged
        )

        content.gesture(gesture)
    }
}

@MainActor
public struct SpatialPressingGesture: UIGestureRecognizerRepresentable {
    public typealias UIGestureRecognizerType = UILongPressGestureRecognizer

    public final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        // Main-actor UI callback; no @Sendable required.
        var onChange: ((CGPoint?) -> Void)?
        var coordinateSpace: CoordinateSpaceProtocol?
        var converter: CoordinateSpaceConverter?

        @objc func handle(_ recognizer: UILongPressGestureRecognizer) {
            switch recognizer.state {
            case .began:
                if let converter, let coordinateSpace {
                    onChange?(converter.location(in: coordinateSpace))
                }
            case .ended, .cancelled, .failed:
                onChange?(nil)
            case .recognized:
                break
            case .changed:
                break
            default:
                break
            }
        }

        public func gestureRecognizer(
            _: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith _: UIGestureRecognizer
        ) -> Bool {
            false
        }

        public func gestureRecognizer(_: UIGestureRecognizer, shouldBeRequiredToFailBy _: UIGestureRecognizer) -> Bool {
            true
        }

        public func gestureRecognizer(_: UIGestureRecognizer, shouldRequireFailureOf _: UIGestureRecognizer) -> Bool {
            false
        }
    }

    let coordinateSpace: CoordinateSpaceProtocol
    let minimumPressDuration: TimeInterval
    let allowableMovement: CGFloat
    // Main-actor UI callback; no @Sendable required.
    let onChange: (CGPoint?) -> Void

    public init(
        coordinateSpace: some CoordinateSpaceProtocol,
        minimumPressDuration: TimeInterval,
        allowableMovement: CGFloat,
        onChange: @escaping (CGPoint?) -> Void
    ) {
        self.coordinateSpace = coordinateSpace
        self.minimumPressDuration = minimumPressDuration
        self.allowableMovement = allowableMovement
        self.onChange = onChange
    }

    public func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
        let coordinator = Coordinator()
        coordinator.converter = converter
        return coordinator
    }

    public func makeUIGestureRecognizer(context: Context) -> UILongPressGestureRecognizer {
        let recognizer = UILongPressGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handle(_:))
        )
        recognizer.minimumPressDuration = minimumPressDuration
        recognizer.allowableMovement = allowableMovement
        recognizer.delegate = context.coordinator
        return recognizer
    }

    public func updateUIGestureRecognizer(_ recognizer: UILongPressGestureRecognizer, context: Context) {
        recognizer.minimumPressDuration = minimumPressDuration
        recognizer.allowableMovement = allowableMovement
        context.coordinator.onChange = onChange
        context.coordinator.coordinateSpace = coordinateSpace
    }
}

public extension View {
    func onPressingChanged(
        in coordinateSpace: CoordinateSpaceProtocol,
        minimumPressDuration: TimeInterval = 0.5,
        allowableMovement: CGFloat = 10,
        _ action: @escaping @MainActor (CGPoint?) -> Void
    ) -> some View {
        modifier(
            SpatialPressingGestureModifier(
                coordinateSpace: coordinateSpace,
                minimumPressDuration: minimumPressDuration,
                allowableMovement: allowableMovement,
                action: action
            )
        )
    }
}
