//  MsgCellGesture.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import SwiftUI
import Database
import Services

private enum MsgCellGestureThresholds {
    static let dragMinDistance: CGFloat = 80
    static let markTrigger: CGFloat = 170
}

@MainActor @Observable final class GestureViewModel {

    var draggedOffset: CGFloat = 0
    var isLongPressActive = false
    @ObservationIgnored private(set) var draggedLimitReached = false
    @ObservationIgnored private var lastAppliedOffset: CGFloat = 0

    func applyDrag(translation: CGFloat, isSender: Bool, onMark: () -> Void) {
        guard isValidDirection(translation, isSender: isSender) else {
            resetOffsetIfNeeded()
            return
        }
        let magnitude = abs(translation)
        if !draggedLimitReached,
            magnitude > MsgCellGestureThresholds.markTrigger
        {
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

    private func isValidDirection(_ translation: CGFloat, isSender: Bool)
        -> Bool
    {
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

struct MsgCellGesture<Content: View>: View, @MainActor Equatable {

    let viewModel: MsgCellViewModel
    let content: () -> Content

    private let gestureModel: GestureViewModel = .init()
    @State private var overlayItem: OverlayMenuItem?
    @Environment(\.msgCellActions) private var msgCellActions

    var body: some View {
        content()
            .offset(x: round(gestureModel.draggedOffset))
            .gesture(
                doubleTapGesture
                    .exclusively(
                        before:
                            longPressGesture
                            .exclusively(before: dragGesture)
                    ),
                including: .gesture
            )
            .background(longPressOverlay)
    }

    static func == (lhs: MsgCellGesture<Content>, rhs: MsgCellGesture<Content>)
        -> Bool
    {
        lhs.viewModel.id == rhs.viewModel.id
    }
}

extension MsgCellGesture {
    private var doubleTapGesture: some Gesture {
        TapGesture(count: 2).onEnded {
            msgCellActions?(.onTapMsg(viewModel.id))
        }
    }

    private var longPressGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.5)
            .onEnded { value in
                if value {
                    activateLongPressIfNeeded()
                }
            }
    }

    private var dragGesture: some Gesture {
        DragGesture(
            minimumDistance: MsgCellGestureThresholds.dragMinDistance,
            coordinateSpace: .local
        ).onChanged { value in
            gestureModel.applyDrag(
                translation: value.translation.width,
                isSender: viewModel.state.isSender
            ) { msgCellActions?(.onMarkMsg(viewModel.msg.uid)) }
        }.onEnded { _ in gestureModel.reset(animated: true) }
    }

    @ViewBuilder private var longPressOverlay: some View {
        if gestureModel.isLongPressActive {
            Color.clear
                .hidden()
                .allowsHitTesting(false)
                .accessibilityHidden(true)
                .onGeometryChange(for: CGRect.self) { proxy in
                    proxy.frame(in: .global)
                } action: { frame in
                    withTransaction(.withoutAnimation()) {
                        overlayItem = .init(id: viewModel.id, frame: frame)
                    }
                }
                .fullScreenCover(
                    item: $overlayItem,
                    onDismiss: {
                        gestureModel.isLongPressActive = false
                    }
                ) { item in
                    OverlayMenu(item: item)
                        .environment(viewModel)
                        .id(viewModel.id)
                        .presentationBackground(.clear)
                        .transition(.movingParts.snapshot)
                }
        }
    }

    private func activateLongPressIfNeeded() {
        guard !gestureModel.isLongPressActive else { return }
        Task { @MainActor in
            gestureModel.isLongPressActive = true
        }
    }
}
