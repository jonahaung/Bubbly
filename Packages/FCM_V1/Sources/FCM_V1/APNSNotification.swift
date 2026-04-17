//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import Foundation

public struct APNSNotification: Codable {
    public let validateOnly: Bool
    public let message: Message

    public struct Message: Codable {
        public let token: String
        public let data: [String: String]
        public let apns: APNS
    }

    public struct APNS: Codable {
        public let payload: Payload
    }

    public struct Payload: Codable {
        public let aps: APNSPayload
    }

    public init(
        validateOnly: Bool = false,
        deviceToken: String,
        messageContent: String,
        aps: APNSPayload,
        customData: [String: String] = [:]
    ) {
        self.validateOnly = validateOnly
        var data = customData
        data.removeValue(forKey: "message")
        data["message"] = messageContent
        message = .init(
            token: deviceToken,
            data: data,
            apns: .init(payload: .init(aps: aps))
        )
    }

    public init(
        validateOnly: Bool = false,
        deviceToken: String,
        messageContent: String,
        alert: APNSAlert,
        badge: Int? = 1,
        sound: APNSSoundType? = .normal("paper.wav"),
        hasContentAvailable: Bool? = true,
        hasMutableContent: Bool? = true,
        category: String? = nil,
        threadID: String? = nil,
        targetContentId: String? = nil,
        interruptionLevel: APNSPayload.InterruptionLevel? = nil,
        relevanceScore: Float? = nil,
        filterCriteria: String? = nil,
        customData: [String: String] = [:]
    ) {
        let aps = APNSPayload(
            alert: alert,
            badge: badge,
            sound: sound,
            hasContentAvailable: hasContentAvailable,
            hasMutableContent: hasMutableContent,
            category: category,
            threadID: threadID,
            targetContentId: targetContentId,
            interruptionLevel: interruptionLevel,
            relevanceScore: relevanceScore,
            filterCriteria: filterCriteria
        )
        self.init(
            validateOnly: validateOnly,
            deviceToken: deviceToken,
            messageContent: messageContent,
            aps: aps,
            customData: customData
        )
    }

    enum CodingKeys: String, CodingKey {
        case validateOnly = "validate_only"
        case message
    }

    public func data(prettyPrinted: Bool = false) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = prettyPrinted ? [.prettyPrinted, .sortedKeys] : [.sortedKeys]
        return try encoder.encode(self)
    }
}
