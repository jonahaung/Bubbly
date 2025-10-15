//
//  Bubble.swift
//  Services
//
//  Created by Aung Ko Min on 1/10/25.
//

import XUI
import Core

public struct Bubble: Conformable {
	public var bubbleCorner: BubbleCorner
	public var showAvatar: Bool { bubbleCorner == .all || bubbleCorner == .receivingBottom }

	public init(
		bubbleCorner: BubbleCorner = .none
	) {
		self.bubbleCorner = bubbleCorner
	}
}
