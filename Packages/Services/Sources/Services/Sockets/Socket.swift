import Core
import Database
import FCM_V1
import Foundation
import XUI

@globalActor
public struct SocketActor {
	public actor SocketActor {}
	public static let shared = SocketActor()
}

@SocketActor
public final class Socket: Sendable {
	@SocketActor public static let shared = Socket()

	let cryptoService = CryptoService.shared
	let pushNotificationSender = PushNotificationSender(suitName: AppInformation.groupID)

	private init() {}

	let queue = AsyncSerialQueue()
	var sendingQueue = Deque<AnyMsgData>()

	enum SocketError: Error {
		case encodingFailed
		case encryptionFailed
	}
}
