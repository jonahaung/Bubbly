//
//  OutgoingSocket.swift
//  MsgRoom
//
//  Created by Aung Ko Min on 24/6/24.
//

import Foundation
import XUI
import FCM_V1
import Core

@globalActor
public struct SocketActor {
	public actor SocketActor { }
	public static let shared = SocketActor()
}

public actor Socket {
	enum SocketError: Error {
		case encodingFailed
	}
	let pushNotificationSender = PushNotificationSender(
		suitName: AppInformation.groupID
	)
	public static let shared = Socket()
	internal let cryptoService =  CryptoService.shared
	private init() {}

	let queue = AsyncSerialQueue()
}
