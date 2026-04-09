// © 2026 Aung Ko Min

import Core
import Database
import Foundation
import Services
import XUI

// MARK: - ChatDataReceiverDelegate

@MainActor
protocol ChatDataReceiverDelegate: AnyObject {
    func chatDataReceiver(didInsert msg: Message)
    func chatDataReceiver(didReceiveMsg msg: Message)
    func chatDataReceiver(didRemove msg: Message, animated: Bool)
    func chatDataReceiver(didUpdate msg: Message, animated: Bool)
    func chatDataReceiver(didReceive status: AnyMsgData.SeenStatusPayload)
    func chatDataReceiver(didReceive typingStatus: AnyMsgData.TypingStatusPayload)
    func chatDataReceiver(didRecieveError error: Error)
}

// MARK: - ChatDataReceiver

@MainActor
final class ChatDataReceiver {
    // MARK: Lifecycle

    init(conID: String) {
        NotificationCenter.default
            .publisher(for: .msgNoti(for: conID))
            .compactMap(\.anyMsgData)
            .receive(on: RunLoop.current)
            .sink { [weak self] data in
                guard let self else {
                    return
                }

                queue.addOperation { [weak self] in
                    guard let self else {
                        return
                    }

                    await performUpdate(data)
                }
            }
            .store(in: cancelBag)
    }

    deinit {
        cancelBag.cancel()
    }

    // MARK: Internal

    weak var delegate: ChatDataReceiverDelegate? = nil

    func performUpdate(_ data: AnyMsgData) async {
        switch data {
        case let .newMsg(rMsg):
            let msg = Message(rMsg)
            delegate?.chatDataReceiver(didInsert: msg)
            if !msg.isSender {
                delegate?.chatDataReceiver(didReceiveMsg: msg)
            }
        case let .updatedMsg(rMsg):
            delegate?.chatDataReceiver(didUpdate: Message(rMsg), animated: false)
        case let .reaction(reaction):
            if let msg = try? await Store.shared.msgStore?.fetch(uid: reaction.msgID) {
                delegate?.chatDataReceiver(didUpdate: msg, animated: false)
            }
        case let .typingStatus(status):
            delegate?.chatDataReceiver(didReceive: status)
        case let .deleteMsg(rMsg):
            do {
                try await Store.shared.msgStore?.delete(uid: rMsg.uid)
                delegate?.chatDataReceiver(didRemove: Message(rMsg), animated: true)
            } catch {
                delegate?.chatDataReceiver(didRecieveError: error)
            }
        case let .seenStatus(status):
            delegate?.chatDataReceiver(didReceive: status)
        }
    }

    // MARK: Private

    private let queue: AsyncQueue = .init()
    private let cancelBag: CancelBag = .init()
}
