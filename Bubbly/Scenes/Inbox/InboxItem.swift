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

struct InboxItem: Sendable, Hashable, Identifiable {
	
	var id: String { msg.uid }
	let conversation: ConversationSnapshot
	let msg: MsgSnapshot
	let sender: ContactSnapshot

	var title: String {
		conversation.name
	}
}

extension InboxItem: ImageViewItem {
	var imageID: String {
		url.lastPathComponent
	}
	var url: URL {
		.init(string: conversation.photoURL?.string ?? "") ?? DemoImages.demoPhotosURLs[0]
	}

	var type: Services.MediaType {
		.png
	}
}
