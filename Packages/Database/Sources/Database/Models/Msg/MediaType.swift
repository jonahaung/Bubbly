//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public enum MediaType: Hashable, CaseIterable {
    case png, video, audio, data
    public var fileExtension: String {
        switch self {
        case .png: ".png"
        case .video: ".mp4"
        case .audio: ".m4a"
        case .data:
            ""
        }
    }

    public var directory: String {
        switch self {
        case .png: "photos"
        case .video: "videos"
        case .audio: "audios"
        case .data:
            "data"
        }
    }
}
