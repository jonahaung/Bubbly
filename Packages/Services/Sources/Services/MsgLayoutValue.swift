//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Database
import SwiftUI
import XUI

public struct MsgLayoutValue: Sendable, Hashable, Equatable, UIdentifiable {
    public let uid: String

    public init(uid: String) {
        self.uid = uid
    }

    public static let empty = MsgLayoutValue(
        uid: String()
    )
}

public struct MsgLayoutValueKey: LayoutValueKey {
    public static let defaultValue: MsgLayoutValue = .empty
}

extension Message {
    public func layoutValue() -> MsgLayoutValue {
        .init(
            uid: uid
        )
    }
}
