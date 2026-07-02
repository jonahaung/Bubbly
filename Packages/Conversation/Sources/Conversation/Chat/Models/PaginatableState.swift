//
//  PaginatableState.swift
//  Conversation
//
//  Created by Aung Ko Min on 12/5/26.
//

import Foundation

struct PaginatableState: Sendable, Hashable {
    let canLoadOlder: Bool
    let canLoadNewer: Bool
    let canAdjustSize: Bool
}
