//
//  Attachment.swift
//  Database
//
//  Created by Aung Ko Min on 23/9/25.
//

import Foundation

public struct Attachment: Codable, Sendable, Hashable {
    public let uid: String
    public var url: String
    public var attachMentTypeRaw: Int
    public let aspectRatio: Double

    public init(uid: String,
                url: String,
                attachMentTypeRaw: Int,
                aspectRatio: Double)
    {
        self.uid = uid
        self.url = url
        self.attachMentTypeRaw = attachMentTypeRaw
        self.aspectRatio = aspectRatio
    }
}

public extension Attachment {
    var attachmentType: AttachMentType {
        .init(rawValue: attachMentTypeRaw) ?? .image
    }
}
