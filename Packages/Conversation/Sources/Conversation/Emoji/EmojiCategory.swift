// © 2026 Aung Ko Min

#if os(iOS)
//
    // Copyright © 2026 Aung Ko Min. All rights reserved.
//

    import Foundation

    struct EmojiCategory: Hashable, Identifiable {
        let id: UUID = .init()
        let title: String
        let iconName: String
        let emojis: [Emoji]
    }

#endif
