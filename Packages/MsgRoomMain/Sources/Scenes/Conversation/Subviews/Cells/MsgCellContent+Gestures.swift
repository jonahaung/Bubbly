//
//  MsgCellContent+Gestures.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 19/9/25.
//

import Database
import Services
import SwiftUI
import XUI

struct MsgCellContentGesturesView<Content: View>: View {
    @Environment(MsgCellViewModel.self) private var viewModel
    @Environment(ChatViewManager.self) private var manager
    @Environment(\.sendMsgCellInteraction) private var sendMsgCellInteraction
    @State private var draggedLimitReached = false
    @State private var draggedOffset: CGFloat = .zero
    @State private var isLongPressActive = false

    private let content: Content

    init(_ content: Content) {
        self.content = content
    }

    var body: some View {
        content
            .offset(x: draggedOffset)
            .gesture(
                dragGesture.exclusively(
                    before: tapGesture
                ),
                including: .gesture
            )
            .background {
                if isLongPressActive {
                    Color.clear.hidden()
                        .onGeometryChange(for: CGRect.self) { proxy in
                            proxy.frame(in: .global)
                        } action: { newValue in
                            isLongPressActive = false
                            sendMsgCellInteraction?(
                                .onFocusMsgBubble(
                                    .init(
                                        id: viewModel.id,
                                        frame: newValue
                                    )
                                )
                            )
                        }
                }
            }
            .onPressingChanged(in: .local) { _ in
                MainActor.assumeIsolated {
                    isLongPressActive = true
                }
            }
            .sensoryFeedback(
                .impact(
                    flexibility: .rigid,
                    intensity: 0.5
                ),
                trigger: isLongPressActive
            )
    }
}

extension MsgCellContentGesturesView {
    private var tapGesture: some Gesture {
        TapGesture(count: 2)
            .onEnded { _ in
                sendMsgCellInteraction?(.onTapMsg(viewModel.id))
            }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 80, coordinateSpace: .local)
            .onChanged { value in
                let width = value.translation.width
                let isValid = viewModel.isSender ? width < -80 : width > 80
                guard isValid else { return }
                let absWidth = abs(width)
                if !draggedLimitReached, absWidth > 170 {
                    draggedLimitReached = true
                    sendMsgCellInteraction?(.onMarkMsg(viewModel.msg))
                }
                guard !draggedLimitReached else { return }
                draggedOffset = width
            }
            .onEnded { _ in
                draggedLimitReached = false
                guard draggedOffset != 0 else { return }
                withTransaction(.init(animation: .interactiveSpring)) {
                    draggedOffset = 0
                }
            }
    }
}
