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
				if try await Store.shared.msgStore.isExisted(uid: rMsg.uid) {
					AudioService.shared.playMessageIncoming()
					self.notifyMessage(data)
				}
			}
		case .updatedMsg(let rMsg):
			queue.addOperation {
				if try await Store.shared.msgStore.isExisted(uid: rMsg.uid) {
					self.notifyMessage(data)
				}
			}
		case .typingStatus:
			queue.addOperation {
				self.notifyMessage(data)
			}
		case .reaction:
			queue.addOperation {
				self.notifyMessage(data)
			}
		case .deleteMsg:
			queue.addOperation {
				self.notifyMessage(data)
			}
		case .seenStatus(status: let status):
			queue.addOperation {
				self.notifyMessage(data)
			}
		}
	}
}
