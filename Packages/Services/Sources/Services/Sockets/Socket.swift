// © 2026 Aung Ko Min

import Core
import Database
import FCM_V1
import Foundation
import XUI

@globalActor
public struct SocketActor {
    public actor SocketActor {}
    public static let shared: SocketActor = .init()
}

@SocketActor
public final class Socket: Sendable {
    @SocketActor public static let shared: Socket = .init()

    let cryptoService: CryptoService = .shared
    let pushNotificationSender: PushNotificationSender = .init(suitName: AppInformation.groupID)

    private init() {}

    public let queue = AsyncQueue()

    enum SocketError: Error {
        case encodingFailed
        case encryptionFailed
    }
}
