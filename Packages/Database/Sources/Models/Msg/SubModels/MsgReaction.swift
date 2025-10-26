//
//  MsgReactionType.swift
//  MsgRoom
//
//  Created by Aung Ko Min on 6/4/24.
//

import Foundation
import XUI

public struct MsgReaction: RawRepresentable, Codable, Sendable, Hashable, ExpressibleByStringLiteral {

    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    public init(stringLiteral: String) {
        self.init(rawValue: stringLiteral)
    }
}
