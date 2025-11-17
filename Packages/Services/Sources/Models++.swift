//
//  Models++.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 4/9/25.
//

import Database
import Foundation
import ImageLoader
import SwiftUI
import XUI

extension Contact: @retroactive ImageViewItem {
    public var remoteURL: URL? {
        .init(string: photoURL) ?? DemoImages.demoPhotosURLs.random()!
    }

    public var subFolderName: String? {
        "Contacts"
    }

    public var folderName: String? {
        mediaType?.directory
    }

    public var imageID: String? {
        uid
    }

    public var mediaType: Database.MediaType? {
        .png
    }
}

extension Database.Group: @retroactive ImageViewItem {
    public var remoteURL: URL? {
        .init(string: photoURL ?? "") ?? DemoImages.demoPhotosURLs.random()!
    }

    public var subFolderName: String? {
        "Conversations"
    }

    public var imageID: String? {
        uid
    }

    public var mediaType: Database.MediaType? {
        .png
    }
}

extension Message: @retroactive ImageViewItem {
    public var remoteURL: URL? {
        guard let string = attachment?.url else { return nil }
        return .init(string: string)
    }

    public var imageID: String? {
        attachment?.uid
    }

    public var subFolderName: String? {
        uid
    }

    public var mediaType: MediaType? {
        switch attachment?.attachmentType {
        case .image:
            MediaType.png
        case .imageUploading:
            MediaType.png
        case .video:
            .video
        case .videoUploading:
            .video
        case .link:
            .data
        case nil:
            nil
        }
    }
}
