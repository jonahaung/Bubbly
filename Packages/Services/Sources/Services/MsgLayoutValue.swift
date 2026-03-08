//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Database
import SwiftUI
import XUI

public struct MsgLayoutValue: Sendable, Hashable, Equatable, UIdentifiable {
    public let uid: String
    public let signature: Int

    public init(uid: String, signature: Int = 0) {
        self.uid = uid
        self.signature = signature
    }

    public static let empty = MsgLayoutValue(
        uid: String(),
        signature: 0
    )
}

public struct MsgLayoutValueKey: LayoutValueKey {
    public static let defaultValue: MsgLayoutValue = .empty
}

extension Message {
    public func layoutValue() -> MsgLayoutValue {
        var hasher = Hasher()
        hasher.combine(uid)
        hasher.combine(text)
        hasher.combine(attachments)
        hasher.combine(reactions)
        hasher.combine(isSender)
		return MsgLayoutValue(
			uid: uid,
			signature: hasher.finalize()
		)
    }
}
