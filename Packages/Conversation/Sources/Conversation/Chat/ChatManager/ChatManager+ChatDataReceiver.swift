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
        if models.contains(withID: msg.uid) {
            models.update(msg: msg)
            return
        }
        switch true {
        case models.isAbsoluteScrolled(at: .bottom):
            scrollController.send(.begin(.append(msg: msg)))
        case models.canPaginate(at: .bottom):
            ToastPresenter.shared.dismiss()
            let toast = Toast(
                node: Text(msg.displayText).opaqueView(),
                allowsBackgroundTap: true
            ) { [weak self] in
                guard let self else { return }
                serialQueue.addOperation { [weak self] in
                    guard let self else { return }
                    try await scrollTo(msg: msg)
                    ToastPresenter.shared.dismiss()
                }
            }
            ToastPresenter.show(toast)
        default:
            
            ToastPresenter.shared.dismiss()
            let toast = Toast(
                node: Text(msg.displayText).opaqueView(),
                allowsBackgroundTap: true
            ) { [weak self] in
                guard let self else { return }
                scrollController.performScroll(to: .id(msg.uid, anchor: .bottom, .animated()))
                ToastPresenter.shared.dismiss()
            }
            ToastPresenter.show(toast)
            models.insert(msg: msg)
            layoutIfNeeded()
        }
    }

    func chatDataReceiver(didReceiveMsg msg: Message) async {
        do {
            try await setIncomingMsgsAsRead(before: msg.date)
        } catch { await showError(error) }
    }

    func chatDataReceiver(didUpdate msg: Message, animated _: Bool) {
        models.update(msg: msg)
    }

    func chatDataReceiver(didRemove msg: Message, animated _: Bool) {
        models.remove(msg: msg)
        let transition = Transaction.withAnimation(.snappy)
        withTransaction(transition) { layoutIfNeeded() }
    }

    func chatDataReceiver(
        didReceive payload: AnyMsgData.MsgRecipientReceiptPayload
    ) async throws {
        try await models.refreshMsg(uid: payload.msgID)
        try await reloadConversation(refetch: false)
        let models = models.storage.filter { model in
            model.state.isSender && model.state.outgoingStatus?.aggregateStatus ?? .initial < .read
        }
        try await self.models.refreshMsgs(uids: models.map(\.id))
    }
}
