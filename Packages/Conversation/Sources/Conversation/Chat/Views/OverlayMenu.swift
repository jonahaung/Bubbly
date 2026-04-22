// © 2026 Aung Ko Min

import Core
import Database
import Services
import SFSafeSymbols
import SwiftUI
import UIKit
import XUI

// MARK: - OverlayMenu

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

    let item: OverlayMenuItem
    @Environment(\.conversationTheme) private var theme
    var body: some View {
        ZStack {
            Rectangle()
                .fill(
                    theme.backgroundColor
                        .opacity(transitionState.isDidAppear ? 0.8 : 0),
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
                            transaction.addAnimationCompletion(criteria: .removed) {
                                withTransaction(.withoutAnimation()) {
                                    dismiss()
                                }
                            }
                            withTransaction(transaction) {
                                transitionState = .hidden
                            }
                        },
                )

            ReactionsBar { reaction in
                msgCellActions?(.onReact(viewModel.msg, reaction))
                dismiss()
            }
            .position(
                x: item.frame.midX,
                y: item.frame.minY - (transitionState == .didAppear ? 15 : -15),
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

    

    @Environment(MsgCellViewModel.self) private var viewModel
    @Environment(\.msgCellActions) private var msgCellActions
    @Environment(\.conversation) private var conversation
    @State private var transitionState: TransitState = .hidden
    @Environment(ChatManager.self) private var manager

    private func dismiss() {
        withTransaction(\.disablesAnimations, true) {
            msgCellActions?(.onFocusMsgBubble(nil))
        }
    }
}

// MARK: - RoomFocesedOverlayBar

struct RoomFocesedOverlayBar: View {
    

    var body: some View {
        HStack(spacing: 0) {
            AnimatedButton(.center) {
                Task {
                    let msg = item.msg
                    try? await Socket.send(
                        .deleteMsg(rMsg: .init(msg)),
                        conversation: conversation,
                    )
                    await MainActor.run {
                        msgCellActions?(.onFocusMsgBubble(nil))
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

    

    @Environment(\.conversation) private var conversation
    @Environment(\.msgCellActions) private var msgCellActions
    @Environment(MsgCellViewModel.self) private var item
    @State private var showInfo = false

    private let iconStyle = SystemImageWithShape.IconStyle.circle(.plain)
}
