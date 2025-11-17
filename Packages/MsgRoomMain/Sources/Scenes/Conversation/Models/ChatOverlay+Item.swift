//
//  ChatOverlay+Item.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 12/7/25.
//

import Database
import Foundation
import Services

extension ChatOverlayView {
    struct Item: Hashable, Sendable, Identifiable {
        let id: String
        var frame: CGRect
        init(id: String, frame: CGRect) {
            self.id = id
            self.frame = frame
        }

        func hash(into hasher: inout Hasher) {
            id.hash(into: &hasher)
        }

        static func == (lhs: Item, rhs: Item) -> Bool {
            lhs.id == rhs.id
        }
    }
}
