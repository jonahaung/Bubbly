//
//  EmojiCategory.swift
//  Conversation
//
//  Created by Aung Ko Min on 15/5/26.
//

import Foundation

struct EmojiCategory: Hashable, Identifiable {
    let id: UUID = .init()
    let title: String
    let iconName: String
    let emojis: [Emoji]
}
