#if os(iOS)
//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

struct EmojiRepository {
    // MARK: - Properties

    @MainActor
    static let shared = EmojiRepository()
    private(set) var categories: [EmojiCategory] = []
    private(set) var emojis: [Emoji] = []

    // MARK: - Initializers

    init() {
        do {
            let emojis = try decodeEmojis()
            categories = sortCategories(for: emojis)
            self.emojis = categories.flatMap(\.emojis)
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    // MARK: - Helpers

    private func decodeEmojis() throws -> [Emoji] {
        let bundle = Bundle.module
        let url = bundle.url(
            forResource: "emojis",
            withExtension: "json"
        )
        let data = try Data(contentsOf: url!)
        return try JSONDecoder().decode([Emoji].self, from: data)
    }

    private func sortCategories(for emojis: [Emoji]) -> [EmojiCategory] {
        var categories: [EmojiCategory] = []

        for categoryType in EmojiCategoryType.allCases {
            let emojis = emojis.filter {
                $0.category == categoryType.title
            }

            let category = EmojiCategory(
                title: categoryType.title,
                iconName: categoryType.iconName,
                emojis: emojis
            )

            categories.append(category)
        }

        return categories
    }
}

#endif
