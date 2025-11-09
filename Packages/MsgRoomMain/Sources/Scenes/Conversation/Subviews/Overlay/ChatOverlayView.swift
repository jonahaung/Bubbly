//
//  ChatOverlayView.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 23/10/24.
//

import Core
import Database
import Services
import SFSafeSymbols
import SwiftUI
import UIKit
import XUI

struct ChatOverlayView: View {
    let item: ChatOverlayView.Item
    let viewModel: MsgCellViewModel
    @Environment(ChatViewManager.self) private var manager
    var body: some View {
        ZStack {
            BlurredBackgroundView {
                manager.eventsManager.updateFocusedFrame(nil)
            }
            MsgCellContent()
                .frame(size: item.frame.size)
                .position(x: item.frame.midX, y: item.frame.midY)

            ReactionsView()
                .position(x: item.frame.midX, y: item.frame.minY)

            RoomFocesedOverlayBar()
                .position(x: item.frame.midX, y: item.frame.maxY + 20)
        }
        .statusBarHidden()
        .environment(viewModel)
    }
}

public struct ReactionRotateButton<Label: View>: View {
    let alignment: HorizontalAlignment
    let label: () -> Label
    let action: () -> Void
    @State private var scaleRotate = false

    public init(
        _ alignment: HorizontalAlignment,
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.label = label
        self.action = action
        self.alignment = alignment
    }

    public var body: some View {
        Button {
            withAnimation(.interpolatingSpring(
                stiffness: 170, damping: 10
            )) {
                scaleRotate.toggle()
            } completion: {
                withAnimation(.bouncy(extraBounce: 0.4)) {
                    scaleRotate = false
                } completion: {
                    action()
                }
            }
        } label: {
            label()
                .rotationEffect(
                    .degrees(scaleRotate ? alignment == .leading ? -45 : 45 : 0),
                    anchor: alignment == .leading ? .bottomLeading : .bottomTrailing
                )
                .scaleEffect(scaleRotate ? 1.8 : 1)
                .offset(y: scaleRotate ? -40 : 0)
        }
        //		.sensoryFeedback(.selection, trigger: scaleRotate)
    }
}

public struct ReactionJumpButton<Label: View>: View {
    enum Reaction: CaseIterable {
        case initial, move, scale
        var verticalOffset: Double {
            switch self {
            case .initial: 0
            case .move, .scale: -64
            }
        }

        var scale: Double {
            switch self {
            case .initial: 1
            case .move, .scale: 2.0
            }
        }

        var chromaRotate: Double {
            switch self {
            case .initial: 0.0
            case .move, .scale: 225.0
            }
        }
    }

    let label: () -> Label
    let action: () -> Void
    @State private var reactionCount = 0

    public init(action: @escaping () -> Void, @ViewBuilder label: @escaping () -> Label) {
        self.label = label
        self.action = action
    }

    public var body: some View {
        Button {
            reactionCount += 1
            DispatchQueue.delay(1.3) {
                action()
            }
        } label: {
            label()
        }
        //		.sensoryFeedback(.selection, trigger: reactionCount)
        .phaseAnimator(
            Reaction.allCases,
            trigger: reactionCount
        ) { heartSymbol, jump in
            heartSymbol
                .scaleEffect(jump.scale)
                .offset(y: jump.verticalOffset)
                .hueRotation(.degrees(jump.chromaRotate))
        } animation: { jump in
            switch jump {
            case .initial: .bouncy(duration: 0.5, extraBounce: 0.25)
            case .move: .easeInOut(duration: 0.3).delay(0.25)
            case .scale: .spring(duration: 0.5, bounce: 0.7)
            }
        }
    }
}

struct RoomFocesedOverlayBar: View {
    @Environment(ChatViewManager.self) private var manager
    @Environment(\.sendChatRoomAction) private var msgRoomAction
    @Environment(MsgCellViewModel.self) private var item

    var body: some View {
        HStack {
            ReactionJumpButton {
                let msg = item.msg
                msgRoomAction?(.deleteMsg(rMsg: RMsg(msg)))
                manager.eventsManager.updateFocusedFrame(nil)
            } label: {
                SystemImageWithShape(.trashFill, .square(.color(.red)))
            }

            ReactionRotateButton(.leading) {} label: {
                SystemImageWithShape(.arrowshapeTurnUpLeftFill, .square(.color(.indigo)))
            }.zIndex(10)

            ReactionRotateButton(.trailing) {} label: {
                SystemImageWithShape(.arrowshapeTurnUpRightFill, .square(.color(.indigo)))
            }.zIndex(10)

            SystemImageWithShape(.ellipsis, .circle(.color(.gray)))
                .presentSheet {
                    Text(item.msg.preetyPrinted)
                }
            ReactionJumpButton {
                UIPasteboard.general.string = item.msg.preetyPrinted
                manager.eventsManager.updateFocusedFrame(nil)
            } label: {
                SystemImageWithShape(.squareOnSquareDashed, .square(.color(.teal)))
            }
        }
    }
}

struct BlurredBackgroundView: View {
    @Environment(ChatViewManager.self) private var manager
    var tapAction: (() -> Void)?

    var body: some View {
        manager.conversation.theme.background.color.opacity(0.9)
            .edgesIgnoringSafeArea(.all)
            .onTapGesture {
                tapAction?()
            }
    }
}
