//  OverlayMenu.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import Core
import UIKit
import SwiftUI
import Database
import Services
import SFSafeSymbols

struct OverlayMenu: View {

    enum TransitState: Hashable {
        case appeared
        case didAppear
        case hidden

        var isDidAppear: Bool {
            self == .didAppear
        }

        var isAppeared: Bool {
            self == .appeared
        }
    }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(
                    theme.backgroundColor
                        .opacity(transitionState.isDidAppear ? 0.9 : 0)
                )
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if transitionState == .didAppear {
                                withTransaction(.withAnimation()) {
                                    transitionState = .appeared
                                }
                            }
                        }
                        .onEnded { _ in
                            var transaction = Transaction.withAnimation()
                            transaction.addAnimationCompletion(
                                criteria: .removed
                            ) {
                                withTransaction(.withoutAnimation()) {
                                    dismiss()
                                }
                            }
                            withTransaction(transaction) {
                                transitionState = .hidden
                            }
                        }
                )

            ReactionsBar { reaction in
                msgCellActions?(.onReact(viewModel.msg, reaction))
                dismiss()
            }
            .position(
                x: item.frame.midX,
                y: item.frame.minY - (transitionState == .didAppear ? 15 : -15)
            )
            MsgCellContent(state: viewModel.state)
                .frame(size: item.frame.size)
                .position(x: item.frame.midX, y: item.frame.midY)

            RoomFocesedOverlayBar()
                .position(x: item.frame.midX, y: item.frame.maxY + 10)
                .opacity(transitionState.isDidAppear ? 1 : 0)
        }
        .statusBarHidden()
        .ignoresSafeArea(.container)
        .onAppear {
            var transaction = Transaction.withAnimation()
            transaction.addAnimationCompletion(criteria: .removed) {
                withTransaction(.withAnimation()) {
                    transitionState = .didAppear
                }
            }
            withTransaction(transaction) {
                transitionState = .appeared
            }
        }
    }

    let item: OverlayMenuItem
    @Environment(\.conversationTheme) private var theme
    @Environment(MsgCellViewModel.self) private var viewModel
    @Environment(\.msgCellActions) private var msgCellActions
    @Environment(\.conversation) private var conversation
    @State private var transitionState: TransitState = .hidden

    private func dismiss() {
        withTransaction(\.disablesAnimations, true) {
            msgCellActions?(.onFocusMsgBubble(nil))
        }
    }
}

struct RoomFocesedOverlayBar: View {

    var body: some View {
        HStack(spacing: 0) {
            AsyncButton {
                let msg = item.msg
                try await Socket.send(
                    .deleteMsg(rMsg: .init(msg)),
                    conversation: conversation
                )
                await Task.delay(1)
                msgCellActions?(.onFocusMsgBubble(nil))
            } label: {
                SystemImageWithShape(.trashFill, iconStyle)
            }
            Button {} label: {
                SystemImageWithShape(.arrowshapeTurnUpLeftFill, iconStyle)
            }

            Button {} label: {
                SystemImageWithShape(.arrowshapeTurnUpRightFill, iconStyle)
            }
            Button {
                UIPasteboard.general.string = item.msg.text
            } label: {
                SystemImageWithShape(.squareFilledOnSquare, iconStyle)
            }
            AsyncButton {
                showInfo = true
            } label: {
                SystemImageWithShape(.ellipsis, iconStyle)
            }.padding(.leading)
        }
        .sheet(isPresented: $showInfo) {
            NavigationStack {
                TextEditor(text: .constant(item.msg.preetyPrinted))
                    .textSelection(.enabled)
                    .font(.footnote.monospaced())
                    .scrollIndicators(.hidden)
                    .scrollContentBackground(.hidden)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(role: .close) {
                                showInfo = false
                            }
                        }
                    }
            }
        }
    }

    @Environment(\.conversation) private var conversation
    @Environment(\.msgCellActions) private var msgCellActions
    @Environment(MsgCellViewModel.self) private var item
    @State private var showInfo = false

    private let iconStyle = SystemImageWithShape.IconStyle.circle(
        .color(.secondaryText)
    )
}
