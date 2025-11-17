//
//  ChatViewManager+Updates.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 26/8/25.
//

import Core
import Database
import Services
import SwiftUI
import XUI

extension ChatViewManager: ChatDatasourceDelegate {
    func datasource(didRecieveError: any Error) async {
        await showError(didRecieveError)
    }

    func datasource(didReceive typingStatus: Database.AnyMsgData.TypingStatusPayload) {
        eventsManager.updateTypingStatus(typingStatus)
    }

    func datasource(didInsert msg: Message) {
        if let existingModel = cellItems.first(where: { $0.msg.uid == msg.uid }) {
            existingModel.update(with: msg)
        } else {
            if canResetDatasource {
                ToastPresenter.show(msg.text) { [weak self] in
                    guard let self else { return }
                    resetDatasource()
                }
            } else {
                let newModel = MsgCellViewModel(msg)
                let index = cellItems.insertionIndex(for: newModel, by: \.msg.date)
                let previousItem = cellItems[safe: index - 1]
                let nextItem = cellItems[safe: index + 1]

                if scrollManager.scrolledPosition.nearBottom {
                    scrollManager.updateLoadingState(.appendingItem(msg.uid))
                } else {
                    ToastPresenter.show(msg.text) { [weak self] in
                        guard let self else { return }
                        scrollManager
                            .scroll(
                                to: .layoutID(
                                    value: msg.uid,
                                    anchor: scrollManager.isFirstResponder ? .top : .bottom
                                )
                            )
                    }
                }

                let layout = bubbleFactory.msgCellLayout(
                    for: msg,
                    previous: previousItem?.msg,
                    next: nextItem?.msg
                )
                newModel.update(layout: layout)
                cellItems.insert(newModel, at: index)
                if let previousItem {
                    previousItem.update(layout: msgCellLayoutFor(previousItem.msg, cellItems: cellItems))
                }
                if let nextItem {
                    nextItem.update(layout: msgCellLayoutFor(nextItem.msg, cellItems: cellItems))
                }
            }
        }
        Task {
            try? await conversation.saveChanges()
        }
    }

    func datasource(didReceiveMsg msg: Message) async {
        updateReceiveMsgs()
        conversation.lastMsgID = msg.uid
        conversation.lastMsgID = msg.uid
        try? await conversation.saveChanges()
    }

    func datasource(didUpdate snapshot: Message, animated: Bool) {
        guard let viewModel = cellItems.first(where: { $0.id == snapshot.uid }) else { return }
        withTransaction(animated ? .withAnimation : .withoutAnimation) {
            viewModel.update(with: snapshot)
        }
    }

    func datasource(didRemove snapshot: Message, animated: Bool) {
        withTransaction(animated ? .withAnimation : .withoutAnimation) {
            cellItems.removeAll { $0.id == snapshot.uid }
        }
    }

    func datasource(didReceive _: Database.AnyMsgData.SeenStatusPayload) async {
        try? await reloadConversation()
    }
}

extension ChatViewManager {
    func setCellItems(_ items: [MsgCellViewModel], animated: Bool = false) {
        for cellItem in items {
            if cellItem.layout.isEmpty {
                let layout = msgCellLayoutFor(cellItem.msg, cellItems: items)
                cellItem.update(layout: layout)
            }
        }
        if animated {
            withTransaction(.withAnimation) {
                cellItems = items
            }
        } else {
            cellItems = items
        }
    }

    func createCellItems(for msgs: [Message], forceReset: Bool) -> [MsgCellViewModel] {
        var newItems = forceReset ? [] : cellItems
        for msg in msgs {
            if let existing = cellItems.first(where: { $0.id == msg.uid }) {
                existing.update(with: msg)
                if forceReset {
                    newItems.append(existing)
                }
            } else {
                let item = MsgCellViewModel(msg)
                let index = newItems.insertionIndex(for: item, by: \.msg.date)
                newItems.insert(item, at: index)
            }
        }
        return newItems
    }

    func reloadConversation() async throws {
        conversation = try await conversation.reload(refetch: false)
    }

    func updateReceiveMsgs() {
        guard let lastMsg = cellItems.last?.msg,
              lastMsg.receiptType == .receive,
              lastMsg.incomingStatus.rawValue < MsgIncomingStatus.read.rawValue,
              let currentUserId
        else {
            return
        }
        Task.detached { [self] in
            do {
                let msgs = try await ConversationRepo.updateReceiveMsgs(for: lastMsg.conID)
                try await Socket.shared.send(
                    .seenStatus(
                        status: .init(
                            msgID: lastMsg.uid,
                            userID: currentUserId,
                            conID: lastMsg.conID
                        )
                    ),
                    conversation: conversation
                )
                await MainActor.run {
                    for msg in msgs {
                        if let model = self.cellItems.first(where: { $0.msg.uid == msg.uid }) {
                            model.update(with: msg)
                        }
                    }
                }
            } catch {
                await showError(error)
            }
        }
    }
}
