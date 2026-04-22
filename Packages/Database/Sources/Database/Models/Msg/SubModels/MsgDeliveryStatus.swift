//  MsgDeliveryStatus.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import XUI
import Foundation

public enum DeliveryStatus: Int, Conformable, Codable, CaseNameReflectable {
    case received
    case read
    case sending
    case delivered
    case sendingFailed
}
