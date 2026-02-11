//
//  Socket+Extensions.swift
//  Services
//
//  Created by Aung Ko Min on 26/8/25.
//

import Database
import XUI

public extension Socket {
	func receive(_ data: AnyMsgData) {
		switch data {
		case let .newMsg(rMsg):
			Task { @SocketActor [weak self] in
				guard let self else { return }
				await queue.addOperation {
					if try await Store.shared.msgStore?.exists(uid: rMsg.uid) == true {
						TonePlayer.play(.tap1)
						await self.notifyMessage(data)
					}
				}
			}
		case .updatedMsg:
			Task { @SocketActor [weak self] in
				guard let self else { return }
				await queue.addOperation {
					await self.notifyMessage(data)
				}
			}
		case .typingStatus:
			Task { @SocketActor [weak self] in
				guard let self else { return }
				await queue.addOperation {
					await self.notifyMessage(data)
				}
			}
		case .reaction:
			Task { @SocketActor [weak self] in
				guard let self else { return }
				await queue.addOperation {
					await self.notifyMessage(data)
				}
			}
		case .deleteMsg:
			Task { @SocketActor [weak self] in
				guard let self else { return }
				await queue.addOperation {
					await self.notifyMessage(data)
				}
			}
		case .seenStatus:
			Task { @SocketActor [weak self] in
				guard let self else { return }
				await queue.addOperation {
					await self.notifyMessage(data)
				}
			}
		}
	}
}
