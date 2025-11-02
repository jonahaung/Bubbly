//
//  ChatToastItem.swift
//  MsgRoom
//
//  Created by Aung Ko Min on 19/4/24.
//

import Foundation
import XUI

public enum ChatToastItem: Conformable {
    case scrollDownButton
    case message(_ msg: Message)
    case none
	public var isEmpty: Bool {
		self == .none
	}
	public var isNotEmpty: Bool { !isEmpty }
}
