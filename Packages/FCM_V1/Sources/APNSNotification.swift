//
//  APNSNotification.swift
//  FCM_V1
//
//  Created by Aung Ko Min on 13/7/25.
//

import Foundation

public struct APNSNotification: Codable {
    public let validateOnly: Bool
    public let message: Message

    public struct Message: Codable {
        public let token: String
        public let data: DataPayload
        public let apns: APNS
    }

    public struct DataPayload: Codable {
        public let message: String
    }

    public struct APNS: Codable {
        public let payload: Payload
    }

    public struct Payload: Codable {
        public let aps: APS
    }

    public struct APS: Codable {
        public let mutableContent: Int
        public let contentAvailable: Int
        public let sound: String
        public let badge: Int
        public let alert: Alert

        enum CodingKeys: String, CodingKey {
            case mutableContent = "mutable-content"
            case contentAvailable = "content-available"
            case sound, badge, alert
        }

        public init(
            mutableContent: Bool = true,
            contentAvailable: Bool = true,
            sound: String = "default",
            badge: Int = 1,
            alert: Alert
        ) {
            self.mutableContent = mutableContent ? 1 : 0
            self.contentAvailable = contentAvailable ? 1 : 0
            self.sound = sound
            self.badge = badge
            self.alert = alert
        }
    }

    public struct Alert: Codable {
        public let title: String
    }

    public init(
        validateOnly: Bool = false,
        deviceToken: String,
        messageContent: String,
        title: String
    ) {
        self.validateOnly = validateOnly
        message = Message(
            token: deviceToken,
            data: DataPayload(message: messageContent),
            apns: APNS(
                payload: Payload(
                    aps: APS(
                        alert: Alert(title: title)
                    )
                )
            )
        )
    }

    public func data(prettyPrinted: Bool = true) throws -> Data {
        let encoder = JSONEncoder()
        if prettyPrinted {
            encoder.outputFormatting = .prettyPrinted
        }
        return try encoder.encode(self)
    }
}
