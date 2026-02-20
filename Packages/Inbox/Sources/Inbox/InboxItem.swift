import Database
import Foundation
import Services
import XUI

struct InboxItem: Sendable, Identifiable, Equatable {

	static func == (lhs: InboxItem, rhs: InboxItem) -> Bool {
		lhs.id == rhs.id
	}

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
	var imageName: String? {
		conversation.name
	}

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
