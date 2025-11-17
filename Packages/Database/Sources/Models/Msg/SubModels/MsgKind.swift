//
//  MsgKind.swift
//  MsgRoom
//
//  Created by Aung Ko Min on 6/4/24.
//

import UIKit
import XUI

public enum MsgKind: Int, Codable, Sendable, Hashable {
    case text, markdown, image, video, location, emoji, attachment, voice
}

public extension MsgKind {
    var shouldPrefatchData: Bool {
        switch self {
        case .image, .video, .location, .attachment:
            true
        default:
            false
        }
    }
}
