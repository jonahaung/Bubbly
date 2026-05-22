//  ChatDataReceiver.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import Core
import Database
import Services
import Foundation

@MainActor protocol ChatDataReceiverDelegate: AnyObject {
    func chatDataReceiver(didInsert msg: Message) async
    func chatDataReceiver(didReceiveMsg msg: Message) async
    func chatDataReceiver(didRemove msg: Message, animated: Bool) async
    func chatDataReceiver(didUpdate msg: Message, animated: Bool) async throws
    func chatDataReceiver(didReceive payload: AnyMsgData.MsgRecipientReceiptPayload) async throws
    func chatDataReceiver(didReceive typingStatus: AnyMsgData.TypingStatusPayload) async
    func chatDataReceiver(didRecieveError error: Error)
}

@MainActor final class ChatDataReceiver {
    init(_ conID: String) {
        NotificationCenter.default.publisher(for: .msgNoti(for: conID)).compactMap(\.anyMsgData)
            .receive(on: RunLoop.current).sink { [weak self] data in
                guard let self else { return }
                queue.addOperation { [weak self] in
                    guard let self else { return }
                    try await performUpdate(data)
                }
            }.store(in: cancelBag)
    }

    deinit {
        queue.cancelAllPendingTasks()
        cancelBag.cancel()
    }

    func performUpdate(_ data: AnyMsgData) async throws {
        switch data {
        case let .newMsg(rMsg):
            let msg = Message(rMsg)
            await delegate?.chatDataReceiver(didInsert: msg)
            if !msg.isSender { await delegate?.chatDataReceiver(didReceiveMsg: msg) }
        case let .updatedMsg(rMsg):
            try await delegate?.chatDataReceiver(didUpdate: Message(rMsg), animated: false)
        case let .reaction(reaction):
            if let msg = try await Store.shared.msgStore?.fetch(uid: reaction.msgID) {
                try await delegate?.chatDataReceiver(didUpdate: msg, animated: false)
            }
        case let .typingStatus(status): await delegate?.chatDataReceiver(didReceive: status)
        case let .deleteMsg(rMsg):
            try await Store.shared.msgStore?.delete(uid: rMsg.uid)
            await delegate?.chatDataReceiver(didRemove: Message(rMsg), animated: true)
        case let .msgRecipientReceipt(payload: payload):
            try await delegate?.chatDataReceiver(didReceive: payload)
        }
    }

    weak var delegate: ChatDataReceiverDelegate?
    private let queue: AsyncQueue = .init()
    private let cancelBag: CancelBag = .init()
}
