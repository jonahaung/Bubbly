//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import Foundation

public struct APNSAlert: Codable, Sendable {
    public let title: String?
    public let subtitle: String?
    public let body: String?
    public let titleLocKey: String?
    public let titleLocArgs: [String]?
    public let actionLocKey: String?
    public let locKey: String?
    public let locArgs: [String]?
    public let launchImage: String?

    /// - Parameters:
    ///   - title: The title to be displayed to the user.
    ///   - subtitle: The subtitle to be displayed to the user.
    ///   - body: The body of the push notification.
    ///   - titleLocKey: The key to a title string in the Localizable.strings file for the current localization.
    ///   - titleLocArgs: Variable string values to appear in place of the format specifiers in `titleLocKey`.
    ///   - actionLocKey: A localized string key used for the action button title instead of “View”.
    ///   - locKey: A key to an alert-message string in a Localizable.strings file for the current localization.
    ///   - locArgs: Variable string values to appear in place of the format specifiers in `locKey`.
    ///   - launchImage: The filename of an image file in the app bundle.
    public init(
        title: String? = nil,
        subtitle: String? = nil,
        body: String? = nil,
        titleLocKey: String? = nil,
        titleLocArgs: [String]? = nil,
        actionLocKey: String? = nil,
        locKey: String? = nil,
        locArgs: [String]? = nil,
        launchImage: String? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.body = body
        self.titleLocKey = titleLocKey
        self.titleLocArgs = titleLocArgs
        self.actionLocKey = actionLocKey
        self.locKey = locKey
        self.locArgs = locArgs
        self.launchImage = launchImage
    }

    enum CodingKeys: String, CodingKey {
        case title
        case subtitle
        case body
        case titleLocKey = "title-loc-key"
        case titleLocArgs = "title-loc-args"
        case actionLocKey = "action-loc-key"
        case locKey = "loc-key"
        case locArgs = "loc-args"
        case launchImage = "launch-image"
    }
}
