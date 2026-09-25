//  ChatManager+MsgCellInteraction.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Core
import Database
import Services
import SwiftUI
import XUI

// MARK: - Interaction Handling

extension ChatManager {

    func handleMsgCellInteraction(action: MsgCellAction.ActionType) {
        switch action {
        case .onTapMsg(let id):
            setSelectedMsg(id)

        case .onMarkMsg(let id):
            markMsg(id)

        case .onTapAvatar(let id):
            handleTapAvatar(id: id)

        case .onFocusMsgBubble(let frame):
            presentation.send(.overlayItem(frame))
            layoutIfNeeded()

        case .onUploadedAttachments(let msg):
            handleUploadedAttachments(msg: msg)

        case .onReact(let message, let reactionType):
            handleReaction(message: message, reactionType: reactionType)

        case .performSend(let data):
            handleSend(data: data)
        }
    }
}

// MARK: - Action Handlers

extension ChatManager {

    private func handleTapAvatar(id: String) {
        guard let viewModel = messages.element(withID: id) else { return }
        guard let contact = members.contact(for: viewModel.msg.senderID) else { return }
        router?.pushToNav(.contactDetails(contact))
    }

    private func handleUploadedAttachments(msg: Message) {
        Task {
            do {
                guard let attachments = msg.attachments else { return }
                try await Store.shared.msgStore?.updateAndSave(uid: msg.uid) { model in
                    model.attachments = attachments
                }
                try await messages.refreshMsg(uid: msg.uid)
                try await Socket.shared.send(.updatedMsg(rMsg: .init(msg)))
            } catch {
                log(error)
            }
        }
    }

    private func handleReaction(message: Message, reactionType: ReactionType) {
        Task {
            do {
                let currentUserID = try CurrentUserID.get()
                let reaction = Reaction(rawValue: reactionType.rawValue, senderID: currentUserID, date: .now)
                let payload = AnyMsgData.ReactionPayload(reaction: reaction, msgID: message.uid, conID: message.conID)
                try? await Socket.shared.send(.reaction(payload: payload))
            } catch {
                log(error)
            }
        }
    }

    private func handleSend(data: AnyMsgData) {
        Task {
            try? await Socket.shared.performSend(data)
        }
    }
}

// MARK: - Selection

private extension ChatManager {

    func setSelectedMsg(_ uid: String) {
        guard let index = messages.index(of: uid) else { return }

        let oldValue = messages.selectedMsg
        let newValue = makeSelection(uid: uid, index: index, oldValue: oldValue)

        withTransaction(.withAnimation(.interactiveSpring)) {
            updateSelection(from: oldValue, to: newValue)
            messages.selectedMsg = newValue
        }
    }

    func markMsg(_ uid: String) {
        print(uid)
    }

    func makeSelection(uid: String, index: Int, oldValue: SelectedMsg?) -> SelectedMsg? {
        guard oldValue?.id != uid else { return nil }

        let nextMessage = messages[index + 1]?.msg
        let previousMessage = messages[index - 1]?.msg

        return SelectedMsg(
            id: uid,
            previous: previousMessage?.uid,
            next: nextMessage?.uid
        )
    }

    func updateSelection(from oldValue: SelectedMsg?, to newValue: SelectedMsg?) {
        if let oldValue {
            applySelectionChange(newValue, around: oldValue.id)
            if let id = oldValue.next {
                applySelectionChange(newValue, around: id)
            }
            if let id = oldValue.previous {
                applySelectionChange(newValue, around: id)
            }
        }

        if let newValue {
            applySelectionChange(newValue, around: newValue.id)
            if let id = newValue.next {
                applySelectionChange(newValue, around: id)
            }
            if let id = newValue.previous {
                applySelectionChange(newValue, around: id)
            }
        }
    }

    func applySelectionChange(_ selection: SelectedMsg?, around id: String) {
        messages.didChangeSelection(selection, for: id)
    }
}
