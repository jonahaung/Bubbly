//
//  InboxItem.swift
//  Bubbly
//
//  Created by Aung Ko Min on 28/5/25.
//

import Database
import Foundation
import Services
import XUI

struct InboxItem: Sendable, Identifiable {
	var id: String {
		msg.uid + sender.uid
	}

	let conversation: Conversation
	let msg: Message
	let sender: any ContactRepresentableSendable
	let unreadMsgsCount: Int
	var title: String {
		conversation.name
	}
}

extension InboxItem: ImageViewItem {
	var subFolders: [String] {
		switch conversation.kind {
		case let .contact(contact):
			contact.subFolders
		case let .group(group):
			group.subFolders
		}
	}

	var galleryTitle: String? {
		switch conversation.kind {
		case let .contact(contact):
			contact.galleryTitle
		case let .group(group):
			group.galleryTitle
		}
	}

	var imageID: String {
		switch conversation.kind {
		case let .contact(contact):
			contact.imageID
		case let .group(group):
			group.imageID
		}
	}

	var remoteURL: URL? {
		switch conversation.kind {
		case let .contact(contact):
			contact.remoteURL
		case let .group(group):
			group.remoteURL
		}
	}
}
