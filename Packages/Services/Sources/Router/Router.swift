//
//  ChatRoomRouter.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 23/10/24.
//

import SwiftUI
import Database
import Core
import Combine
import XUI

@MainActor
@Observable
public class Router {

	public static let shared = Router()

	private let cancelBag = CancelBag()

	public var tab: TabPath = .inbox
	public var navRouters = TabPath.allCases.map { NavRouter($0) }
	public var currentNavRouter: NavRouter? {
		navRouters.first(where: { $0.id == tab })
	}
	public var currentNavPath: NavPath? {
		currentNavRouter?.navPath.last
	}

	public func navRouter(for tab: TabPath) -> NavRouter {
		navRouters.first(where: { $0.id.id == tab.id })!
	}
	private init() {
		registerForRemoteNotifications()
	}

	public func push(_ path: NavPath) {
		currentNavRouter?.push(path)
	}
	public func replace(_ paths: [NavPath]) {
		currentNavRouter?.replace(paths)
	}

}

private extension Router {
	func registerForRemoteNotifications() {
		NotificationCenter.default
			.publisher(for: .tapPushNotificationAction)
			.receive(on: RunLoop.main)
			.sink { notification in
				guard let userInfo = notification.userInfo else {
					return
				}
				guard let data = AnyMsgData(userInfo: userInfo) else {
					return
				}
				ConversationInitializer.start(conID: data.conID, refetch: false, delay: 1)
			}
			.store(in: cancelBag)
	}
}
