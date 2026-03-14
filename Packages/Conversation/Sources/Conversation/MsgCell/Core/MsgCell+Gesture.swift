//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Database
import Services
import SwiftUI
import XUI

extension MsgCell {

    private enum MsgCellGestureThresholds {
        static let dragMinDistance: CGFloat = 80
        static let markTrigger: CGFloat = 170
    }

    @Observable
    final class GestureViewModel {

        var draggedOffset: CGFloat = 0
        var isLongPressActive = false

        @ObservationIgnored
        private(set) var draggedLimitReached = false

        @ObservationIgnored
        private var lastAppliedOffset: CGFloat = 0

        func applyDrag(
            translation: CGFloat,
            isSender: Bool,
            onMark: () -> Void
        ) {
            guard isValidDirection(translation, isSender: isSender) else {
                resetOffsetIfNeeded()
                return
            }

            let magnitude = abs(translation)

            if !draggedLimitReached,
               magnitude > MsgCellGestureThresholds.markTrigger {
                draggedLimitReached = true
                onMark()
            }

            guard !draggedLimitReached else { return }

            let rounded = round(translation)

            if abs(rounded - lastAppliedOffset) >= 1 {
                draggedOffset = rounded
                lastAppliedOffset = rounded
            }
        }

        func reset(animated: Bool) {
            draggedLimitReached = false

            guard draggedOffset != 0 else { return }

            if animated {
                withTransaction(.init(animation: .interactiveSpring)) {
                    draggedOffset = 0
                    lastAppliedOffset = 0
                }
            } else {
                draggedOffset = 0
                lastAppliedOffset = 0
            }
        }

        private func isValidDirection(
            _ translation: CGFloat,
            isSender: Bool
        ) -> Bool {
            isSender
                ? translation < -MsgCellGestureThresholds.dragMinDistance
                : translation > MsgCellGestureThresholds.dragMinDistance
        }

        private func resetOffsetIfNeeded() {
            guard !draggedLimitReached else { return }
            draggedOffset = 0
            lastAppliedOffset = 0
        }
    }
}

extension MsgCell {

    struct GestureAware<Content: View>: View {

        @Environment(MsgCellViewModel.self) private var viewModel
        @Environment(\.msgCellActions) private var sendInteraction

        @State private var model = GestureViewModel()

        let content: () -> Content

        var body: some View {
            content()
                .offset(x: round(model.draggedOffset))
                .highPriorityGesture(dragGesture, including: .gesture)
                .simultaneousGesture(doubleTapGesture)
                .background {
                    longPressOverlay
                }
                .onPressingChanged(in: .local) { _ in
                    activateLongPressIfNeeded()
                }
        }
    }
}

extension MsgCell.GestureAware {

    private var doubleTapGesture: some Gesture {
        TapGesture(count: 2)
            .onEnded {
                sendInteraction?(.onTapMsg(viewModel.id))
            }
    }

    private var dragGesture: some Gesture {
        DragGesture(
            minimumDistance: MsgCell.MsgCellGestureThresholds.dragMinDistance,
            coordinateSpace: .local
        )
        .onChanged { value in
            model.applyDrag(
                translation: value.translation.width,
                isSender: viewModel.state.isSender
            ) {
                sendInteraction?(.onMarkMsg(viewModel.msg))
            }
        }
        .onEnded { _ in
            model.reset(animated: true)
        }
    }

    private var longPressOverlay: some View {
        Group {
            if model.isLongPressActive {
                Color.clear
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                    .onGeometryChange(for: CGRect.self) { proxy in
                        proxy.frame(in: .global)
                    } action: { frame in
                        model.isLongPressActive = false
                        Haptics.play(.rigid, 0.7)
                        withTransaction(.withoutAnimation()) {
                            sendInteraction?(
                                .onFocusMsgBubble(
                                    .init(id: viewModel.id, frame: frame)
                                )
                            )
                        }
                    }
            }
        }
    }

    private func activateLongPressIfNeeded() {
        guard !model.isLongPressActive else { return }
        DispatchQueue.main.async {
            model.isLongPressActive = true
        }
    }
}
