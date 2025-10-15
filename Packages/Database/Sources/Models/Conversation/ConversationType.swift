//
//  RoomType.swift
//  MsgRoom
//
//  Created by Aung Ko Min on 6/4/24.
//

import Foundation
import XUI

public enum ConversationType: Int, Conformable, Codable {
    case single, group
}

extension ConversationType: CustomStringConvertible {
	public var description: String {
		switch self {
		case .single:
			return "single"
		case .group:
			return "group"
		}
	}
}
