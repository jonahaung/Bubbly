//
//  PushMeta.swift
//  FCM_V1
//
//  Created by Aung Ko Min on 18/4/26.
//


public struct PushMeta: Codable {
    public let deepLink: String?

    enum CodingKeys: String, CodingKey {
        case deepLink = "deep_link"
    }
}