//
//  PaginatableState.swift
//  Conversation
//
//  Created by Aung Ko Min on 12/5/26.
//

import Foundation

struct PaginatableState: Sendable, Hashable {
    var canLoadOlder: Bool
    var canLoadNewer: Bool
    var canAdjustSize: Bool
}
