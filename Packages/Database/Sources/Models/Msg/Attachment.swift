//
//  Attachment.swift
//  Database
//
//  Created by Aung Ko Min on 23/9/25.
//

import Foundation

public struct Attachment: Codable, Sendable, Hashable, Identifiable {
	
	public var id: String { uid }
	public let uid: String
	public var url: String
	public var thumbnailUrl: String?
	public var attachMentTypeRaw: Int
	public let aspectRatio: Double
	public let title: String?
	public let subTitle: String?
	
	public init(
		uid: String,
		url: String,
		thumbnailUrl: String? = nil,
		attachMentTypeRaw: Int,
		aspectRatio: Double,
		title: String? = nil,
		subTitle: String? = nil
	) {
		self.uid = uid
		self.url = url
		self.thumbnailUrl = thumbnailUrl
		self.attachMentTypeRaw = attachMentTypeRaw
		self.aspectRatio = aspectRatio
		self.title = title
		self.subTitle = subTitle
	}
}

public extension Attachment {
	var attachmentType: AttachMentType {
		.init(rawValue: attachMentTypeRaw) ?? .image
	}
	
	var displayText: String {
		attachmentType.displayText
	}
}
