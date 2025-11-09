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
        case .image: "Image"
        case .imageUploading: "Uploading Image"
        case .video: "Video"
        case .videoUploading: "Uploading Video"
        case .link: "Link"
        }
    }
}
