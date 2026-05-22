//  ChatManager+MsgCellInteraction.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import SwiftUI
import Database
import Services
import Core

extension ChatManager {
    func handleMsgCellInteraction(action: MsgCellAction.ActionType) {
        switch action {
        case let .onTapMsg(string): setSelectedMsg(string)
        case .onMarkMsg: break
        case let .onTapAvatar(string):
            guard let vieModel = messages.element(withID: string) else { return }
            if let contact = members.contact(for: vieModel.msg.senderID) {
                router?.pushToNav(.contactDetails(contact))
            }
        case let .onFocusMsgBubble(frame):
            presentation.send(.overlayItem(frame))
            layoutIfNeeded()
        case let .onUploadedAttachments(msg):
            serialQueue.addOperation { [weak self] in
                guard let self else { return }
                try await Store.shared.msgStore?.updateAndSave(uid: msg.uid) { model in
                    model.attachments = msg.attachments
                }
                try await messages.refreshMsg(uid: msg.uid)
            }
        case let .onReact(message, reactionType):
            serialQueue.addOperation {
                let currentUserID = try CurrentUserID.get()
                try? await Socket.shared.send(
                    .reaction(
                        payload: .init(
                            reaction: .init(
                                rawValue: reactionType.rawValue, senderID: currentUserID,
                                date: .now
                            ),
                            msgID: message.uid,
                            conID: message.conID
                        )
                    )
                )
            }
        case let .performSend(data):
            serialQueue.addOperation {
                try await Socket.shared.performSend(data)
            }
        }
    }
}

private extension ChatManager {
    func setSelectedMsg(_ uid: String) {
        guard let index = messages.index(of: uid) else { return }
        let oldValue = messages.selectedMsg
        let nextMsg = messages[index + 1]?.msg
        let previousMsg = messages[index - 1]?.msg
        let newValue: SelectedMsg? =
            oldValue?.id == uid
                ? nil : SelectedMsg(id: uid, previous: previousMsg?.uid, next: nextMsg?.uid )
        let transaction = Transaction.withAnimation(.interactiveSpring)
        withTransaction(transaction) {
            if let oldValue {
                messages.didChangeSelection(newValue, for: oldValue.id)
                if let id = oldValue.next { messages.didChangeSelection(newValue, for: id) }
                if let id = oldValue.previous { messages.didChangeSelection(newValue, for: id) }
            }
            if let newValue {
                messages.didChangeSelection(newValue, for: newValue.id)
                if let id = newValue.next { messages.didChangeSelection(newValue, for: id) }
                if let id = newValue.previous { messages.didChangeSelection(newValue, for: id) }
            }
            messages.selectedMsg = newValue
        }
    }
}
