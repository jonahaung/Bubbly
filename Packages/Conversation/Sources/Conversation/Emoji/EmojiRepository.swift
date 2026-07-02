//
//  EmojiRepository.swift
//  Conversation
//
//  Created by Aung Ko Min on 15/5/26.
//

import Foundation

struct EmojiRepository {

    @MainActor
    static let shared: EmojiRepository = .init()
    private(set) var categories: [EmojiCategory] = []
    private(set) var emojis: [Emoji] = []

    init() {
        do {
            let emojis = try decodeEmojis()
            categories = sortCategories(for: emojis)
            self.emojis = categories.flatMap(\.emojis)
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    private func decodeEmojis() throws -> [Emoji] {
        let bundle = Bundle.main
        let url = bundle.url(
            forResource: "emojis",
            withExtension: "json"
        )
        let data = try Data(contentsOf: url!)
        return try JSONDecoder().decode([Emoji].self, from: data)
    }

    private func sortCategories(for emojis: [Emoji]) -> [EmojiCategory] {
        var categories = [EmojiCategory]()

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

