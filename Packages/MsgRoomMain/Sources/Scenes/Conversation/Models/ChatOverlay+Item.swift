//
//  ChatOverlay+Item.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 12/7/25.
//

import Foundation
import Database
import Services

extension ChatOverlayView {
	public struct Item: Equatable, Hashable, Sendable, Identifiable {
		public let id: String
		public var frame: CGRect

		public init(id: String, frame: CGRect) {
			self.id = id
			self.frame = frame
		}

		public func hash(into hasher: inout Hasher) {
			id.hash(into: &hasher)
		}
		public static func == (lhs: Item, rhs: Item) -> Bool {
			lhs.id == rhs.id
		}
	}
}
