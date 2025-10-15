//
//  MsgOutgoingStatus.swift
//  Database
//
//  Created by Aung Ko Min on 27/8/25.
//

import Foundation

//public struct MsgOutgoingStatus: Codable, Hashable, Equatable, Sendable {
//
//	public let status: Int
//	public let userID: String
//	public let serverTime: String
//
//	public init(status: Int, userID: String, serverTime: String) {
//		self.status = status
//		self.userID = userID
//		self.serverTime = serverTime
//	}
//
//	public init(
//		_ status: MsgDeliveryStatus,
//		_ userID: String,
//		_ serverTime: ServerTime = .now
//	) {
//		self.status = status.rawValue
//		self.userID = userID
//		self.serverTime = serverTime.value
//	}
//
//	public func hash(into hasher: inout Hasher) {
//		hasher.combine(status)
//		hasher.combine(userID)
//	}
//
//	public static func == (lhs: MsgOutgoingStatus, rhs: MsgOutgoingStatus) -> Bool {
//		lhs.status == rhs.status
//		&& lhs.userID == rhs.userID
//	}
//}
//
//public extension MsgOutgoingStatus {
//	var deleveryStatus: MsgDeliveryStatus {
//		.init(rawValue: status) ?? .sendingFailed
//	}
//	var date: Date {
//		ServerTime(serverTime).date
//	}
//}
//
//extension MsgOutgoingStatus: CustomStringConvertible {
//	public var description: String {
//		"\(deleveryStatus.description) at \(serverTime)"
//	}
//}
//extension MsgOutgoingStatus: Comparable {
//	public static func < (lhs: MsgOutgoingStatus, rhs: MsgOutgoingStatus) -> Bool {
//		lhs.serverTime < rhs.serverTime
//	}
//}
