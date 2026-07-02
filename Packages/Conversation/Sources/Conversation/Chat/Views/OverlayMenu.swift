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
    var body: some View {
        ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(
                    LinearGradient(colors: [Color.background.opacity(0.7), Color.background.opacity(0.9), Color.background.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                )
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            
                        }
                        .onEnded { _ in
                            handleDismiss()
                        }
                )
            MsgCellContent(viewModel: viewModel)
                .frame(size: item.frame.size)
                .offset(x: item.frame.minX, y: item.frame.minY)
            
            ReactionsBar { reaction in
                msgCellActions?(.onReact(viewModel.msg, reaction))
                handleDismiss()
            }
            .offset(x: item.frame.minX, y: item.frame.minY-20)

            RoomFocesedOverlayBar()
                .offset(x: item.frame.minX, y: item.frame.maxY)
        }
        .ignoresSafeArea(.all)
    }

    let item: OverlayMenuItem
    @Environment(\.conversationTheme) private var theme
    @Environment(MsgCellViewModel.self) private var viewModel
    @Environment(\.msgCellActions) private var msgCellActions
    @Environment(\.conversation) private var conversation
    @Environment(\.dismiss) private var dismiss

    private func handleDismiss() {
        withTransaction(\.disablesAnimations, true) {
           dismiss()
        }
    }
}

struct RoomFocesedOverlayBar: View {

    var body: some View {
        HStack(spacing: 0) {
            AsyncButton {
                let msg = item.msg
                try await Socket.shared.send(
                    .deleteMsg(rMsg: .init(msg))
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
                TextEditor(text: .constant(item.msg.prettyPrinted))
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
