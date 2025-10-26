//
//  AttachMentType.swift
//  Database
//
//  Created by Aung Ko Min on 22/10/25.
//

import Foundation
import XUI

public enum AttachMentType: Int, Codable, Sendable, Hashable {
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
