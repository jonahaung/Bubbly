//  ChatToastItem.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import XUI
import Foundation

public enum ChatToastItem: Conformable {
    case scrollDownButton
    case message(_ msg: Message)
    case none
    public var isEmpty: Bool {
        self == .none
    }

    public var isNotEmpty: Bool {
        !isEmpty
    }
}
