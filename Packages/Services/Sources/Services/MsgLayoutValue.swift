//
//  MsgLayoutValue.swift
//  Services
//
//  Created by Aung Ko Min on 23/2/26.
//

import SwiftUI
import XUI
import Database

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
