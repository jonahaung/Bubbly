//
//  Socket++.swift
//  Services
//
//  Created by Aung Ko Min on 26/8/25.
//

import Database

public extension Socket {
    func receive(_ data: AnyMsgData) {
        switch data {
        case let .newMsg(rMsg):
            Task { [weak self] in
                guard let self else { return }
                await queue.addOperation {
					if try await Store.shared.msgStore?.exists(uid: rMsg.uid) == true {
						await AudioService.shared.play(.msgIncoming)
                        await self.notifyMessage(data)
                    }
                }
            }
        case .updatedMsg:
            Task { [weak self] in
                guard let self else { return }
                await queue.addOperation {
                    await self.notifyMessage(data)
                }
            }
        case .typingStatus:
            Task { [weak self] in
                guard let self else { return }
                await queue.addOperation {
                    await self.notifyMessage(data)
                }
            }
        case .reaction:
            Task { [weak self] in
                guard let self else { return }
                await queue.addOperation {
                    await self.notifyMessage(data)
                }
            }
        case .deleteMsg:
            Task { [weak self] in
                guard let self else { return }
                await queue.addOperation {
                    await self.notifyMessage(data)
                }
            }
        case .seenStatus:
            Task { [weak self] in
                guard let self else { return }
                await queue.addOperation {
                    await self.notifyMessage(data)
                }
            }
        }
    }
}
