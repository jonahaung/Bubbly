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
	public var data: Data?
	public var thumbnailData: Data?

	public init(uid: String,
				url: String,
				attachMentTypeRaw: Int,
				aspectRatio: Double,
				data: Data? = nil,
				thumbnailData: Data? = nil) {
		self.uid = uid
		self.url = url
		self.attachMentTypeRaw = attachMentTypeRaw
		self.aspectRatio = aspectRatio
		self.data = data
		self.thumbnailData = thumbnailData
	}
}

public extension Attachment {
	var attachmentType: MsgAttachment.AttachMentType {
		.init(rawValue: attachMentTypeRaw) ?? .image
	}
}
