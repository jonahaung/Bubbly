//  ChatDataReceiver.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Core
import Database
import Foundation
import Services
import UIKit
import XUI

// MARK: - Delegate

@MainActor
protocol ChatDataReceiverDelegate: AnyObject {
    func chatDataReceiver(didInsert msg: Message) async throws
    func chatDataReceiver(didReceiveMsg msg: Message) async throws
    func chatDataReceiver(didRemove msg: Message, animated: Bool) async throws
    func chatDataReceiver(didUpdate msg: Message, animated: Bool) async throws
    func chatDataReceiver(didReceive payload: AnyMsgData.MsgRecipientReceiptPayload) async throws
    func chatDataReceiver(didReceive typingStatus: AnyMsgData.TypingStatusPayload) async throws
    func chatDataReceiver(didRecieveError error: Error) async
    func chatDataReceiverApplicationDidBecomeActive() async throws
    func chatDataReceiverApplicationWillResignActive() async throws
}

// MARK: - Receiver

@MainActor
final class ChatDataReceiver {

    weak var delegate: ChatDataReceiverDelegate?

    private let queue: AsyncQueue = .init()
    private let cancelBag: CancelBag = .init()

    init(_ conversationID: String) {
        observeMessages(for: conversationID)
        observeApplicationDidBecomeActive()
        observeApplicationWillResignActive()
    }

    deinit {
        queue.cancelAllPendingTasks()
        cancelBag.cancel()
    }
}

// MARK: - Message Observation

extension ChatDataReceiver {

    private func observeMessages(for conversationID: String) {
        NotificationCenter.default
            .publisher(for: .msgNoti(for: conversationID))
            .compactMap(\.anyMsgData)
            .receive(on: RunLoop.current)
            .sink { [weak self] data in
                self?.enqueue { receiver in
                    try await receiver.performUpdate(data)
                }
            }
            .store(in: cancelBag)
    }

    private func observeApplicationDidBecomeActive() {
        NotificationCenter.default
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.enqueue { receiver in
                    try await receiver.delegate?.chatDataReceiverApplicationDidBecomeActive()
                }
            }
            .store(in: cancelBag)
    }
    private func observeApplicationWillResignActive() {
        NotificationCenter.default
            .publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.enqueue { receiver in
                    try await receiver.delegate?.chatDataReceiverApplicationWillResignActive()
                }
            }
            .store(in: cancelBag)
    }

    private func enqueue(_ operation: @escaping (ChatDataReceiver) async throws -> Void) {
        queue.addOperation { [weak self] in
            guard let self else { return }
            do {
                try await operation(self)
            } catch {
                await delegate?.chatDataReceiver(didRecieveError: error)
            }
        }
    }
}

// MARK: - Update Dispatch

extension ChatDataReceiver {

    func performUpdate(_ data: AnyMsgData) async throws {
        switch data {
        case .newMsg(let rawMessage):
            try await handleNewMessage(rawMessage)

        case .updatedMsg(let rawMessage):
            try await delegate?.chatDataReceiver(didUpdate: Message(rawMessage), animated: false)

        case .reaction(let reaction):
            try await handleReaction(reaction)

        case .typingStatus(let status):
            try await delegate?.chatDataReceiver(didReceive: status)

        case .deleteMsg(let rawMessage):
            try await handleDelete(rawMessage)

        case .msgRecipientReceipt(let payload):
            try await delegate?.chatDataReceiver(didReceive: payload)
        }
    }

    private func handleNewMessage(_ rawMessage: RMsg) async throws {
        let message = Message(rawMessage)
        try await delegate?.chatDataReceiver(didInsert: message)

        guard !message.isSender else { return }
        try await delegate?.chatDataReceiver(didReceiveMsg: message)
    }

    private func handleReaction(_ reaction: AnyMsgData.ReactionPayload) async throws {
        guard let message = try await Store.shared.msgStore?.fetch(uid: reaction.msgID) else { return }
        try await delegate?.chatDataReceiver(didUpdate: message, animated: false)
    }

    private func handleDelete(_ rawMessage: RMsg) async throws {
        try await Store.shared.msgStore?.delete(uid: rawMessage.uid)
        try await delegate?.chatDataReceiver(didRemove: Message(rawMessage), animated: true)
    }
}
