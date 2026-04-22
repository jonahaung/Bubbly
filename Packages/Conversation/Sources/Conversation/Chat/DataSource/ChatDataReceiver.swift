// © 2026 Aung Ko Min
import Core
import Database
import Foundation
import Services
import XUI
// MARK: - ChatDataReceiverDelegate
@MainActor protocol ChatDataReceiverDelegate: AnyObject {
    func chatDataReceiver(didInsert msg: Message) async
    func chatDataReceiver(didReceiveMsg msg: Message) async
    func chatDataReceiver(didRemove msg: Message, animated: Bool) async
    func chatDataReceiver(didUpdate msg: Message, animated: Bool) async
    func chatDataReceiver(didReceive status: AnyMsgData.SeenStatusPayload) async
    func chatDataReceiver(didReceive typingStatus: AnyMsgData.TypingStatusPayload) async
    func chatDataReceiver(didRecieveError error: Error)
}
// MARK: - ChatDataReceiver
@MainActor final class ChatDataReceiver {
    init(_ conID: String) {
        NotificationCenter.default.publisher(for: .msgNoti(for: conID)).compactMap(\.anyMsgData)
            .receive(on: RunLoop.current).sink { [weak self] data in
                guard let self else { return }
                queue.addOperation { [weak self] in
                    guard let self else { return }
                    await performUpdate(data)
                }
            }.store(in: cancelBag)
    }
    deinit {
        queue.cancelAllPendingTasks()
        cancelBag.cancel()
    }
    func performUpdate(_ data: AnyMsgData) async {
        switch data {
        case .newMsg(let rMsg):
            let msg = Message(rMsg)
            await delegate?.chatDataReceiver(didInsert: msg)
            if !msg.isSender { await delegate?.chatDataReceiver(didReceiveMsg: msg) }
        case .updatedMsg(let rMsg):
            await delegate?.chatDataReceiver(didUpdate: Message(rMsg), animated: false)
        case .reaction(let reaction):
            if let msg = try? await Store.shared.msgStore?.fetch(uid: reaction.msgID) {
                await delegate?.chatDataReceiver(didUpdate: msg, animated: false)
            }
        case .typingStatus(let status): await delegate?.chatDataReceiver(didReceive: status)
        case .deleteMsg(let rMsg):
            do {
                try await Store.shared.msgStore?.delete(uid: rMsg.uid)
                await delegate?.chatDataReceiver(didRemove: Message(rMsg), animated: true)
            } catch { delegate?.chatDataReceiver(didRecieveError: error) }
        case .seenStatus(let status): await delegate?.chatDataReceiver(didReceive: status)
        }
    }
    weak var delegate: ChatDataReceiverDelegate?
    private let queue: AsyncQueue = .init()
    private let cancelBag: CancelBag = .init()
}
