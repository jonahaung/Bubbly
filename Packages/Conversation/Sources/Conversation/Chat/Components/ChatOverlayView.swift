//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Core
import Database
import Services
import SFSafeSymbols
import SwiftUI
import UIKit
import XUI

struct ChatOverlayView: View {
    enum TransitState: Hashable {
        case appeared, didAppear, hidden

        var isDidAppear: Bool {
            self == .didAppear
        }

        var isAppeared: Bool {
            self == .appeared
        }
    }

    let item: ChatOverlayView.Item
    @Environment(MsgCellViewModel.self) private var viewModel
    @Environment(\.msgCellActions) private var msgCellActions
    @Environment(\.conversation) private var conversation
    @State private var transitionState = TransitState.hidden

    var body: some View {
        ZStack {
            Rectangle().fill(.background.opacity(0.2))
                .glassEffect(.regular, in: .containerRelative)
                .backgroundExtensionEffect()
                .opacity(transitionState.isDidAppear ? 1 : 0)
                .gesture(
                    DragGesture(minimumDistance: 0).onChanged { _ in
                        if transitionState == .didAppear {
                            withTransaction(.withAnimation()) {
                                transitionState = .appeared
                            }
                        }
                    }.onEnded { _ in
                        var transaction = Transaction.withAnimation()
                        transaction.addAnimationCompletion(criteria: .removed) {
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
            MsgCell.Content(state: viewModel.state)
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

    private func dismiss() {
        msgCellActions?(.onFocusMsgBubble(nil))
    }
}

struct RoomFocesedOverlayBar: View {
    @Environment(\.conversation) private var conversation
    @Environment(\.sendChatRoomAction) private var msgRoomAction
    @Environment(MsgCellViewModel.self) private var item
    private let iconStyle = SystemImageWithShape.IconStyle.circle(.plain)
    @State private var showInfo = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        HStack(spacing: 0) {
            AnimatedButton(.center) {
                Task {
                    let msg = item.msg
                    try? await Socket.send(
                        .deleteMsg(rMsg: .init(msg)),
                        conversation: conversation
                    )
                    await MainActor.run {
                        dismiss()
                    }
                }
            } label: {
                SystemImageWithShape(.trashFill, iconStyle)
            }
            AnimatedButton(.leading) {} label: {
                SystemImageWithShape(.arrowshapeTurnUpLeftFill, iconStyle)
            }

            AnimatedButton(.trailing) {} label: {
                SystemImageWithShape(.arrowshapeTurnUpRightFill, iconStyle)
            }
            AnimatedButton(.center) {
                UIPasteboard.general.string = item.msg.text
            } label: {
                SystemImageWithShape(.squareFilledOnSquare, iconStyle)
            }
            AnimatedButton(.center) {
                showInfo = true
            } label: {
                SystemImageWithShape(.ellipsis, iconStyle)
            }.padding(.leading)
        }
        .sheet(isPresented: $showInfo) {
            NavigationStack {
                VStack {
                    TextEditor(text: .constant(item.msg.preetyPrinted))
                        .textSelection(.enabled)
                        .font(.footnote.monospaced())
                        .scrollIndicators(.hidden)
                }
                .padding()
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
}
