//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

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
