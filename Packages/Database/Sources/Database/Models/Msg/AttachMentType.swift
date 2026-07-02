//  AttachMentType.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import XUI
import Foundation

public enum AttachMentType: Int, Codable, Sendable, Hashable {
    case image
    case imageUploading
    case video
    case videoUploading
    case link

    public var description: String {
        switch self {
        case .image: "Image"
        case .imageUploading: "Uploading Image"
        case .video: "Video"
        case .videoUploading: "Uploading Video"
        case .link: "Link"
        }
    }

    var displayText: String {
        switch self {
        case .image: "Photo Message"
        case .imageUploading: "✹"
        case .video: "🎥"
        case .videoUploading: "✹"
        case .link: "Attachment"
        }
    }
}
