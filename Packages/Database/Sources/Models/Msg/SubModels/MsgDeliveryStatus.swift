//
//  MsgDeliveryStatus.swift
//  MsgRoom
//
//  Created by Aung Ko Min on 6/4/24.

import Foundation
import XUI

public enum MsgOutgoingStatus: Int, Codable, Sendable, Hashable, CaseNameReflectable {
	case sending, sent, sendingFailed
}

public extension MsgOutgoingStatus {
	var description: String {
		localizedName
	}
}

public enum MsgIncomingStatus: Int, Conformable, Codable, CaseNameReflectable {
	case none, delivered, read
}
