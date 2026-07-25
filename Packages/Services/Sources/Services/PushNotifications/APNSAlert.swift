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
