//  ChatManager+ChatDataReceiver.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Core
import Database
import SwiftUI
import XUI

// MARK: - ChatDataReceiverDelegate

extension ChatManager: ChatDataReceiverDelegate {
    func chatDataReceiverApplicationWillResignActive() async throws {
        try await saveLastPageIfNeeded()
    }
    func chatDataReceiverApplicationDidBecomeActive() async throws {
        try await messages.updatePagination()
        scrollController.applicationDidBecomeActive()
        try await setIncomingMsgsAsRead(before: .now)
    }

    func chatDataReceiver(didRecieveError error: any Error) async {
        await showError(error)
    }

    func chatDataReceiver(didReceive typingStatus: AnyMsgData.TypingStatusPayload) {
        presentation.send(.typing(typingStatus))
    }

    func chatDataReceiver(didInsert msg: Message) async throws {
        switch messageInsertionContext(for: msg) {
        case .atBottom:
            insertAtBottom(msg: msg)

        case .shouldPaginate:
            showScrollToMessageToast(msg: msg)

        case .shouldNotPaginate:
            try await showNotificationToastAndInsert(msg: msg)
        }
    }

    func chatDataReceiver(didReceiveMsg msg: Message) async throws {
        try await setIncomingMsgsAsRead(before: msg.date)
    }

    func chatDataReceiver(didUpdate msg: Message, animated _: Bool) async throws {
        try await messages.refreshMsg(uid: msg.uid)
    }

    func chatDataReceiver(didRemove msg: Message, animated _: Bool) async throws {
        try await messages.remove(msg: msg)
        withTransaction(Transaction.withAnimation()) {
            layoutIfNeeded()
        }
    }

    func chatDataReceiver(didReceive payload: AnyMsgData.MsgRecipientReceiptPayload) async throws {
        try await messages.refreshMsg(uid: payload.msgID)
        try await reloadConversation(refetch: false)
        try await refreshUnreadOutgoingMessages()
    }
}

// MARK: - Insert Handling

extension ChatManager {

    private enum MessageInsertionContext {
        case atBottom
        case shouldPaginate
        case shouldNotPaginate
    }

    private func messageInsertionContext(for msg: Message) -> MessageInsertionContext {
        if messages.isAbsoluteScrolled(at: .bottom) {
            return .atBottom
        }
        if messages.shouldPaginate(at: .bottom) {
            return .shouldPaginate
        }
        return .shouldNotPaginate
    }

    private func insertAtBottom(msg: Message) {
        scrollController.send(.begin(.append(msg: msg)))
    }

    private func showScrollToMessageToast(msg: Message) {
        let toast = Toast(
            node: Text(msg.displayText).opaqueView(),
            style: .notification
        ) { [weak self] in
            guard let self else { return }

            Task {
                try? await scrollTo(msg: msg)
            }
        }
        ToastPresenter.show(toast)
    }

    private func showNotificationToastAndInsert(msg: Message) async throws {
        let toast = Toast(
            node: Text(msg.displayText).opaqueView(),
            style: .notification
        ) { [weak self] in
            guard let self else { return }
            scrollController.performScroll(to: .id(msg.uid, anchor: .bottom, .animated()))
        }
        ToastPresenter.show(toast)
        try await messages.insert(msg: msg)
        layoutIfNeeded()
    }
}

// MARK: - Receipt Handling

extension ChatManager {

    private func refreshUnreadOutgoingMessages() async throws {
        let unreadMessages = messages.wrappedValue.filter { model in
            model.state.isSender && (model.state.outgoingStatus?.aggregateStatus ?? .sending) < .read
        }
        try await messages.refreshMsgs(uids: unreadMessages.map(\.id))
    }
}
