//
//  InboxItem.swift
//  Bubbly
//
//  Created by Aung Ko Min on 28/5/25.
//

import Foundation
import Database
import Services
import MsgRoomMain
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
		case .contact(let contact):
			return contact.imageID
		case .group(let group):
			return group.imageID
		case .system(let ai):
			return ai.imageID
		}
	}
	var remoteURL: URL? {
		switch conversation.kind {
		case .contact(let contact):
			return contact.remoteURL
		case .group(let group):
			return group.remoteURL
		case .system(let ai):
			return ai.remoteURL
		}
	}
	var mediaType: MediaType? {
		switch conversation.kind {
		case .contact(let contact):
			return contact.mediaType
		case .group(let group):
			return group.mediaType
		case .system(let ai):
			return ai.mediaType

		}
	}
	var subFolderName: String? {
		switch conversation.kind {
		case .contact(let contact):
			return contact.subFolderName
		case .group(let group):
			return group.subFolderName
		case .system(let ai):
			return ai.subFolderName
		}
	}
}
