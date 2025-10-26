//
//  MsgDeliveryStatus.swift
//  MsgRoom
//
//  Created by Aung Ko Min on 6/4/24.

import Foundation
import XUI

public enum MsgOutgoingStatus: Int, Codable, Sendable, Hashable {
	case sending, sent, sendingFailed
}
extension MsgOutgoingStatus {
	public var description: String {
		switch self {
		case .sending:
			return "Sending"
		case .sendingFailed:
			return "Failed"
		case .sent:
			return "Sent"
		}
	}
}

public enum MsgIncomingStatus: Int, Conformable, Codable {
	case none, delivered, read
}
