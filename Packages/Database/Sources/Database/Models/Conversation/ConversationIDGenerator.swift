//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public enum ConversationIDGenerator {
    public static func generate(_ lhs: String, _ rhs: String) -> String {
        lhs > rhs ? rhs + "|" + lhs : lhs + "|" + rhs
    }
}
