// © 2026 Aung Ko Min

import Core
import Database
import FCM_V1
import Foundation
import XUI

// MARK: - SocketActor

@globalActor
public struct SocketActor {
    public actor SocketActor {}
    public static let shared: SocketActor = .init()
}

// MARK: - Socket

@SocketActor
public final class Socket: Sendable {
    @SocketActor public static let shared: Socket = .init()

    let cryptoService: CryptoService = .shared
    let pushNotificationSender: PushNotificationSender = .init(suitName: AppInformation.groupID)

    private init() {}

    let queue: AsyncSerialQueue = .init()
    var sendingQueue: Deque<AnyMsgData> = .init()

    enum SocketError: Error {
        case encodingFailed
        case encryptionFailed
    }
}
