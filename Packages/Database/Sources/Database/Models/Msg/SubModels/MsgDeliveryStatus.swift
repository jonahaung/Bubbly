// © 2026 Aung Ko Min

import Foundation
import XUI

public enum DeliveryStatus: Int, Conformable, Codable, CaseNameReflectable {
    case received
    case read
    case sending
    case delivered
    case sendingFailed
}
