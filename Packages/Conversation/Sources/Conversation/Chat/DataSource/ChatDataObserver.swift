#if os(iOS)
//
//  ChatDataObserver.swift
//  Conversation
//
//  Created by Aung Ko Min on 2/4/26.
//

import Core
import Database
import Foundation
import Services
import XUI

protocol ChatDataObserverDelegate: AnyObject, Sendable {
	func dataObserver(didInsert msg: Message) async
	func dataObserver(didReceiveMsg msg: Message) async
	func dataObserver(didRemove msg: Message, animated: Bool) async
	func dataObserver(didUpdate msg: Message, animated: Bool) async
	func dataObserver(didReceive status: AnyMsgData.SeenStatusPayload) async
	func dataObserver(didReceive typingStatus: AnyMsgData.TypingStatusPayload) async
	func dataObserver(didRecieveError error: Error) async
}

@MainActor
final class ChatDataObserver {

	weak var delegate: ChatDataObserverDelegate?

	private let queue = AsyncQueue()
	private let cancelBag = CancelBag()

	init(conID: String) {
		NotificationCenter.default
			.publisher(for: .msgNoti(for: conID))
			.compactMap(\.anyMsgData)
			.receive(on: RunLoop.current)
			.sink { [weak self] data in
				guard let self else { return }
				queue.addOperation { [weak self] in
					guard let self else { return }
					await performUpdate(data)
				}
			}
			.store(in: cancelBag)
	}

	deinit {
		cancelBag.cancel()
		delegate = nil
	}

	func performUpdate(_ data: AnyMsgData) async {
		switch data {
		case .newMsg(let rMsg):
			let msg = Message(rMsg)
			await delegate?.dataObserver(didInsert: msg)
			if !msg.isSender {
				await delegate?.dataObserver(didReceiveMsg: msg)
			}
		case .updatedMsg(let rMsg):
			await delegate?.dataObserver(didUpdate: Message(rMsg), animated: false)
		case .reaction(let reaction):
			if let msg = try? await Store.shared.msgStore?.fetch(uid: reaction.msgID) {
				await delegate?.dataObserver(didUpdate: msg, animated: false)
			}
		case .typingStatus(let status):
			await delegate?.dataObserver(didReceive: status)
		case .deleteMsg(let rMsg):
			do {
				try await Store.shared.msgStore?.delete(uid: rMsg.uid)
				await delegate?.dataObserver(didRemove: Message(rMsg), animated: true)
			} catch {
				await delegate?.dataObserver(didRecieveError: error)
			}
		case .seenStatus(let status):
			await delegate?.dataObserver(didReceive: status)
		}
	}
}

#endif
