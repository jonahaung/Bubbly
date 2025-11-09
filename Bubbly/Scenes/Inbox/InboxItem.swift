//
//  InboxItem.swift
//  Bubbly
//
//  Created by Aung Ko Min on 28/5/25.
//

import Database
import Foundation
import MsgRoomMain
import Services
import XUI

struct InboxItem: Sendable, Identifiable {
    var id: String { msg.uid + sender.uid }
    let conversation: any ConversationRepresentable
    let msg: Message
    let sender: any ContactRepresentable
    var title: String {
        conversation.name
    }
}

extension InboxItem: ImageViewItem {
    var imageID: String? {
        switch conversation.kind {
        case let .contact(contact):
            contact.imageID
        case let .group(group):
            group.imageID
        case let .system(ai):
            ai.imageID
        }
    }

    var remoteURL: URL? {
        switch conversation.kind {
        case let .contact(contact):
            contact.remoteURL
        case let .group(group):
            group.remoteURL
        case let .system(ai):
            ai.remoteURL
        }
    }

    var mediaType: MediaType? {
        switch conversation.kind {
        case let .contact(contact):
            contact.mediaType
        case let .group(group):
            group.mediaType
        case let .system(ai):
            ai.mediaType
        }
    }

    var subFolderName: String? {
        switch conversation.kind {
        case let .contact(contact):
            contact.subFolderName
        case let .group(group):
            group.subFolderName
        case let .system(ai):
            ai.subFolderName
        }
    }
}
