//
//  Bubble.swift
//  Services
//
//  Created by Aung Ko Min on 1/10/25.
//

import XUI
import Core

public struct Bubble: Hashable, Equatable, Sendable {

	public var id: Int { bubbleCorner.id }
	public var bubbleCorner: BubbleCorner
	public var showAvatar: Bool { bubbleCorner == .all || bubbleCorner == .receivingBottom }

	public init(bubbleCorner: BubbleCorner = .none) {
		self.bubbleCorner = bubbleCorner
	}

	public static func == (lhs: Bubble, rhs: Bubble) -> Bool {
		lhs.bubbleCorner == rhs.bubbleCorner && lhs.id == rhs.id
	}
	public func hash(into hasher: inout Hasher) {
		hasher.combine(bubbleCorner)
	}
}
