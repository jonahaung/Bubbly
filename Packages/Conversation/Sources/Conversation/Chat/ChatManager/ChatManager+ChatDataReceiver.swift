//  ChatManager+ChatDataReceiver.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import Core
import SwiftUI
import Database

extension ChatManager: ChatDataReceiverDelegate {

    func chatDataReceiver(didRecieveError error: any Error) {
        serialQueue.addOperation { [weak self] in
            guard let self else { return }
            await showError(error)
        }
    }

    func chatDataReceiver(
        didReceive typingStatus: AnyMsgData.TypingStatusPayload
    ) {
        presentation.send(.typing(typingStatus))
    }

    func chatDataReceiver(didInsert msg: Message) {
        switch true {
        case messages.isAbsoluteScrolled(at: .bottom):
            scrollController.send(.begin(.append(msg: msg)))
        case messages.shouldPaginate(at: .bottom):
            let toast = Toast(
                node: Text(msg.displayText).opaqueView(),
                style: .notification
            ) { [weak self] in
                guard let self else { return }
                serialQueue.addOperation { [weak self] in
                    guard let self else { return }
                    try await scrollTo(msg: msg)
                }
            }
            ToastPresenter.show(toast)
        case !messages.shouldPaginate(at: .bottom):
            let toast = Toast(
                node: Text(.init(msg.displayText)).opaqueView(),
                style: .notification
            ) { [weak self] in
                guard let self else { return }
                scrollController.performScroll(to: .id(msg.uid, anchor: .bottom, .animated(.interpolatingSpring)))
            }
            ToastPresenter.show(toast)
            messages.insert(msg: msg)
            layoutIfNeeded()
        default:
            break
        }
    }

    func chatDataReceiver(didReceiveMsg msg: Message) async {
        do {
            try await setIncomingMsgsAsRead(before: msg.date)
        } catch { await showError(error) }
    }

    func chatDataReceiver(didUpdate msg: Message, animated _: Bool) {
        serialQueue.addOperation { [weak self] in
            guard let self else { return }
            try await messages.refreshMsg(uid: msg.uid)
        }
    }

    func chatDataReceiver(didRemove msg: Message, animated _: Bool) {
        messages.remove(msg: msg)
        let transition = Transaction.withAnimation(.snappy)
        withTransaction(transition) { layoutIfNeeded() }
    }

    func chatDataReceiver(
        didReceive payload: AnyMsgData.MsgRecipientReceiptPayload
    ) async throws {
        try await messages.refreshMsg(uid: payload.msgID)
        try await reloadConversation(refetch: false)
        let models = messages.wrappedValue.filter { model in
            model.state.isSender && model.state.outgoingStatus?.aggregateStatus ?? .sending < .read
        }
        try await self.messages.refreshMsgs(uids: models.map(\.id))
    }
}
