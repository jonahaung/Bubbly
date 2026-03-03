//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

struct EmojiCategory: Hashable, Identifiable {
    let id = UUID()
    let title: String
    let iconName: String
    let emojis: [Emoji]
}
