//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public enum ConversationKind: Codable, Sendable, Hashable {
    case contact(_ contact: Contact)
    case group(_ group: Group)
}
