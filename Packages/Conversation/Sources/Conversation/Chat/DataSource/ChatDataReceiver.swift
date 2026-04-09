//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import Core
import Database
import Foundation
import Services
import XUI

@MainActor
protocol DataObserverDelegate: AnyObject {
	func dataObserver(didInsert msg: Message)
	func dataObserver(didReceiveMsg msg: Message)
	func dataObserver(didRemove msg: Message, animated: Bool)
	func dataObserver(didUpdate msg: Message, animated: Bool)
	func dataObserver(didReceive status: AnyMsgData.SeenStatusPayload)
	func dataObserver(didReceive typingStatus: AnyMsgData.TypingStatusPayload)
	func dataObserver(didRecieveError error: Error)
}

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

	weak var delegate: DataObserverDelegate?

	func performUpdate(_ data: AnyMsgData) async {
		switch data {
		case let .newMsg(rMsg):
			let msg = Message(rMsg)
			delegate?.dataObserver(didInsert: msg)
			if !msg.isSender {
				delegate?.dataObserver(didReceiveMsg: msg)
			}
		case let .updatedMsg(rMsg):
			delegate?.dataObserver(didUpdate: Message(rMsg), animated: false)
		case let .reaction(reaction):
			if let msg = try? await Store.shared.msgStore?.fetch(uid: reaction.msgID) {
				delegate?.dataObserver(didUpdate: msg, animated: false)
			}
		case let .typingStatus(status):
			delegate?.dataObserver(didReceive: status)
		case let .deleteMsg(rMsg):
			do {
				try await Store.shared.msgStore?.delete(uid: rMsg.uid)
				delegate?.dataObserver(didRemove: Message(rMsg), animated: true)
			} catch {
				delegate?.dataObserver(didRecieveError: error)
			}
		case let .seenStatus(status):
			delegate?.dataObserver(didReceive: status)
		}
	}

	// MARK: Private

	private let queue: AsyncQueue = .init()
	private let cancelBag: CancelBag = .init()

}
