//
//  MsgKind.swift
//  MsgRoom
//
//  Created by Aung Ko Min on 6/4/24.
//

import UIKit
import XUI

public enum MsgKind: Int, Conformable, Codable {
	case text, markdown, image, video, location, emoji, attachment, voice
}

public struct MsgAttachment: Codable, Conformable, Identifiable {

	public var id: String
	public var url: String
	public let attachMentTypeRaw: Int
	public var aspectRatio: Double

	public init(id: String, url: String, attachMentType: AttachMentType, aspectRatio: Double) {
		self.id = id
		self.url = url
		self.attachMentTypeRaw = attachMentType.rawValue
		self.aspectRatio = aspectRatio
	}

	public var attachmentType: AttachMentType {
		.init(rawValue: attachMentTypeRaw) ?? .image
	}

	public init(_ attachment: Attachment) {
		self.init(id: attachment.uid, url: attachment.uid, attachMentType: attachment.attachmentType, aspectRatio: attachment.aspectRatio)
	}
}

public extension MsgAttachment {
	enum AttachMentType: Int, Conformable {
		case image
		case imageUploading
		case video
		case videoUploading
		case link

		public var description: String {
			switch self {
			case .image: return "Image"
			case .imageUploading: return "Uploading Image"
			case .video: return "Video"
			case .videoUploading: return "Uploading Video"
			case .link: return "Link"
			}
		}
	}
}
