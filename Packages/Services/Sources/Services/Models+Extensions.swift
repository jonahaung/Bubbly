// © 2026 Aung Ko Min

import Database
import Foundation
import ImageLoader
import SwiftUI
import XUI

// MARK: - Contact + @retroactive ImageViewItem

extension Contact: @retroactive ImageViewItem {
    public var imageName: String? {
        name
    }

    public var subFolders: [String] {
        ["Contacts", "Profile Photos", uid]
    }

    public var remoteURL: URL? {
        .init(string: photoURL)
    }

    public var imageID: String {
        uid
    }

    public var galleryTitle: String? {
        name
    }
}

// MARK: - Database.Group + @retroactive ImageViewItem

extension Database.Group: @retroactive ImageViewItem {
    public var imageName: String? {
        name
    }

    public var subFolders: [String] {
        ["Groups", "Profile Photos", uid]
    }

    public var galleryTitle: String? {
        name
    }

    public var remoteURL: URL? {
        .init(string: photoURL ?? "") ?? DemoImages.demoPhotosURLs.random()
    }

    public var imageID: String {
        uid
    }
}

// MARK: - Attachment + @retroactive ImageViewItem

extension Attachment: @retroactive ImageViewItem {
    public var imageName: String? {
        "Attachment"
    }

    public var subFolders: [String] {
        var values = ["Conversations", "Messages", "Attachments", attachmentType.description]
        let split = uid.components(separatedBy: "_")
        if split.count == 2 {
            values.append(split[0])
        }
        return values
    }

    public var galleryTitle: String? {
        title
    }

    public var remoteURL: URL? {
        .init(string: url)
    }

    public var imageID: String {
        uid
    }
}
