//
//  Socket++.swift
//  Services
//
//  Created by Aung Ko Min on 26/8/25.
//

import Database

extension Socket {
	func receive(_ data: AnyMsgData) {
		switch data {
		case .newMsg(let rMsg):
			queue.addOperation {
				if try await Store.shared.msgStore.exists(uid: rMsg.uid) {
					AudioService.shared.playMessageIncoming()
					await self.notifyMessage(data)
				}
			}
		case .updatedMsg(let rMsg):
			queue.addOperation {
				if try await Store.shared.msgStore.exists(uid: rMsg.uid) {
					await self.notifyMessage(data)
				}
			}
		case .typingStatus:
			queue.addOperation {
				await self.notifyMessage(data)
			}
		case .reaction:
			queue.addOperation {
				await self.notifyMessage(data)
			}
		case .deleteMsg:
			queue.addOperation {
				await self.notifyMessage(data)
			}
		case .seenStatus(status: _):
			queue.addOperation {
				await self.notifyMessage(data)
			}
		}
	}
}
