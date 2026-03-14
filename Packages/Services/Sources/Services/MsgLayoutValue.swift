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
	public func layoutValue(cellLayout: MsgCellLayout) -> MsgLayoutValue {
		var hasher = Hasher()
		hasher.combine(uid)
		hasher.combine(text?.count ?? 0)
		hasher.combine(isSender)
		hasher.combine(cellLayout.showTimeSeparator)
		hasher.combine(cellLayout.showTopPadding)
		hasher.combine(cellLayout.showAvatar)
		hasher.combine(attachments.count)
		for attachment in attachments {
			hasher.combine(attachment.attachMentTypeRaw)
			hasher.combine(Int((attachment.aspectRatio * 1000).rounded()))
			hasher.combine(attachment.title?.count ?? 0)
			hasher.combine(attachment.subTitle?.count ?? 0)
		}
		hasher.combine(reactions.isEmpty == false)
		let signature = hasher.finalize()
		return MsgLayoutValue(
			uid: uid,
			signature: signature
		)
    }
}
