#if os(iOS)
//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

enum EmojiCategoryType: String, CaseIterable {
    // MARK: - Cases

    case smileysAndEmotion
    case peopleAndBody
    case animalsAndNature
    case foodAndDrink
    case travelAndPlaces
    case activities
    case objects
    case symbols
    case flags

    // MARK: - Properties

    var title: String {
        switch self {
        case .smileysAndEmotion:
            "Smileys & Emotion"
        case .peopleAndBody:
            "People & Body"
        case .animalsAndNature:
            "Animals & Nature"
        case .foodAndDrink:
            "Food & Drink"
        case .travelAndPlaces:
            "Travel & Places"
        case .activities:
            "Activities"
        case .objects:
            "Objects"
        case .symbols:
            "Symbols"
        case .flags:
            "Flags"
        }
    }

    var iconName: String {
        switch self {
        case .smileysAndEmotion:
            "icon.people"
        case .peopleAndBody:
            "icon.body"
        case .animalsAndNature:
            "icon.animals"
        case .foodAndDrink:
            "icon.food"
        case .travelAndPlaces:
            "icon.travel"
        case .activities:
            "icon.activity"
        case .objects:
            "icon.objects"
        case .symbols:
            "icon.symbols"
        case .flags:
            "icon.flags"
        }
    }
}

#endif
