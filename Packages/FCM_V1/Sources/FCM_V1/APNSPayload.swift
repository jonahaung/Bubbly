//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import Foundation

public struct APNSPayload: Codable {
    public let alert: APNSAlert?
    public let badge: Int?
    public let sound: APNSSoundType?
    public let contentAvailable: Int?
    public let mutableContent: Int?
    public let category: String?
    public let threadID: String?
    public let targetContentId: String?
    public let interruptionLevel: InterruptionLevel?
    public let relevanceScore: Float?
    public let filterCriteria: String?

    public init(
        alert: APNSAlert? = nil,
        badge: Int? = nil,
        sound: APNSSoundType? = nil,
        hasContentAvailable: Bool? = nil,
        hasMutableContent: Bool? = nil,
        category: String? = nil,
        threadID: String? = nil,
        targetContentId: String? = nil,
        interruptionLevel: InterruptionLevel? = nil,
        relevanceScore: Float? = nil,
        filterCriteria: String? = nil
    ) {
        self.alert = alert
        self.badge = badge
        self.sound = sound
        contentAvailable = hasContentAvailable == true ? 1 : nil
        mutableContent = hasMutableContent == true ? 1 : nil

        self.category = category
        self.threadID = threadID
        self.targetContentId = targetContentId
        self.interruptionLevel = interruptionLevel
        self.relevanceScore = relevanceScore.map { min(max($0, 0), 1) }
        self.filterCriteria = filterCriteria
    }

    enum CodingKeys: String, CodingKey {
        case alert
        case badge
        case sound
        case contentAvailable = "content-available"
        case mutableContent = "mutable-content"
        case category
        case threadID = "thread-id"
        case targetContentId = "target-content-id"
        case interruptionLevel = "interruption-level"
        case relevanceScore = "relevance-score"
        case filterCriteria = "filter-criteria"
    }

    public enum InterruptionLevel: String, Codable {
        case passive
        case active
        case timeSensitive = "time-sensitive"
        case critical
    }
}
