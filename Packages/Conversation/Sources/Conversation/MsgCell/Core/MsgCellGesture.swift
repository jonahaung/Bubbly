//  MsgCellGesture.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import SwiftUI

// © 2026 Aung Ko Min
import Database
import Services

private enum MsgCellGestureThresholds {
    static let dragMinDistance: CGFloat = 80
    static let markTrigger: CGFloat = 170
}

@Observable final class GestureViewModel {
    var draggedOffset: CGFloat = 0
    var isLongPressActive = false
    @ObservationIgnored private(set) var draggedLimitReached = false
    
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

    @ObservationIgnored private var lastAppliedOffset: CGFloat = 0
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
    @State private var overlayItem: OverlayMenuItem?
    var body: some View {
        content()
            .offset(x: round(model.draggedOffset))
            .highPriorityGesture(dragGesture, including: .gesture)
            .simultaneousGesture(doubleTapGesture)
            .onPressingChanged(in: .local) { _ in
                activateLongPressIfNeeded()
            }
            .background(longPressOverlay)
    }

    @Environment(\.msgCellActions) private var msgCellActions
    @State private var model: GestureViewModel = .init()

    static func == (lhs: MsgCellGesture<Content>, rhs: MsgCellGesture<Content>)
        -> Bool
    {
        lhs.viewModel.state == rhs.viewModel.state
            && lhs.model.isLongPressActive == rhs.model.isLongPressActive
            && lhs.model.draggedLimitReached == rhs.model.draggedLimitReached
            && lhs.model.draggedOffset == rhs.model.draggedOffset
    }
}

extension MsgCellGesture {
    private var doubleTapGesture: some Gesture {
        TapGesture(count: 2).onEnded {
            msgCellActions?(.onTapMsg(viewModel.id))
        }
    }

    private var dragGesture: some Gesture {
        DragGesture(
            minimumDistance: MsgCellGestureThresholds.dragMinDistance,
            coordinateSpace: .local
        ).onChanged { value in
            model.applyDrag(
                translation: value.translation.width,
                isSender: viewModel.state.isSender
            ) { msgCellActions?(.onMarkMsg(viewModel.msg)) }
        }.onEnded { _ in model.reset(animated: true) }
    }

    @ViewBuilder private var longPressOverlay: some View {
        if model.isLongPressActive {
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
                .fullScreenCover(item: $overlayItem, onDismiss: {
                    model.isLongPressActive = false
                }) { item in
                    OverlayMenu(item: item)
                        .environment(viewModel)
                        .id(viewModel.id)
                        .presentationBackground(.clear)
                        .transition(.movingParts.snapshot)
                }
        }
    }

    private func activateLongPressIfNeeded() {
        guard !model.isLongPressActive else { return }
        DispatchQueue.main.async { model.isLongPressActive = true }
    }
}
