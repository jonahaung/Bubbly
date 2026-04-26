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
        if scrollController.isNear(.bottom) {
            scrollController.updateStateUpdate(
                to: .dataUpdate(.append(msgID: msg.uid))
            )
            models.insert(msg: msg)
            layoutIfNeeded()
        } else {
            if scrollCoordinator(scrollController, shouldPaginateAt: .bottom) {
                ToastPresenter.shared.dismiss()
                let toast = Toast(
                    node: Text(msg.displayText).opaqueView(),
                    allowsBackgroundTap: true
                ) { [weak self] in
                    guard let self else { return }
                    ToastPresenter.shared.dismiss()
                    serialQueue.addOperation { [weak self] in
                        guard let self else { return }
                        try await scrollTo(msg: msg)
                    }
                }
                ToastPresenter.show(toast)
            } else {
                models.insert(msg: msg)
                layoutIfNeeded()
                ToastPresenter.shared.dismiss()
                let toast = Toast(
                    node: Text(msg.displayText).opaqueView(),
                    allowsBackgroundTap: false
                ) { [weak self] in
                    guard let self else { return }
                    ToastPresenter.shared.dismiss()
                    serialQueue.addBarrierOperation { [weak self] in
                        guard let self else { return }
                        try await scrollTo(msg: msg)
                    }
                }
                ToastPresenter.show(toast)
            }
        }
    }

    func chatDataReceiver(didReceiveMsg msg: Message) async {
        do {
            try await setIncomingMsgsAsRead(before: msg.date)
        } catch { await showError(error) }
    }

    func chatDataReceiver(didUpdate msg: Message, animated _: Bool){
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
        let models = models.renderedModels.filter { model in
            model.state.isSender && model.state.outgoingStatus?.aggregateStatus ?? .initial < .read
        }
        try await self.models.refreshMsgs(uids: models.map(\.id))
    }
}
