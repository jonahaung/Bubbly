//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Database
import XUI

public extension Socket {
    func receive(_ data: AnyMsgData) {
        switch data {
        case let .newMsg(rMsg):
            Task { @SocketActor [weak self] in
                guard let self else { return }
				try await queue.sync {
                    if try await Store.shared.msgStore?.exists(uid: rMsg.uid) == true {
                        
                        await self.notifyMessage(data)
                    }
                }
            }
        case .updatedMsg:
            Task { @SocketActor [weak self] in
                guard let self else { return }
				await queue.sync {
                    await self.notifyMessage(data)
                }
            }
        case .typingStatus:
            Task { @SocketActor [weak self] in
                guard let self else { return }
				await queue.sync {
                    await self.notifyMessage(data)
                }
            }
        case .reaction:
            Task { @SocketActor [weak self] in
                guard let self else { return }
				await queue.sync {
                    await self.notifyMessage(data)
                }
            }
        case .deleteMsg:
            Task { @SocketActor [weak self] in
                guard let self else { return }
				await queue.sync {
                    await self.notifyMessage(data)
                }
            }
        case .seenStatus:
            Task { @SocketActor [weak self] in
                guard let self else { return }
				
            }
        }
    }
}
