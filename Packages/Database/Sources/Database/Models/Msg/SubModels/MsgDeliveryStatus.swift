//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import XUI

public enum DeliveryStatus: Int, Conformable, Codable, CaseNameReflectable {
	case received, read, sending, delivered, sendingFailed
}

public struct Delivery: Codable, Conformable {
	public let contactID: String
	public let status: DeliveryStatus

	public init(contactID: String, status: DeliveryStatus) {
		self.contactID = contactID
		self.status = status
	}
}
