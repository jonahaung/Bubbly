//
//  Models+Extensions.swift
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
	public var imageName: String? {
		self.name
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

extension Database.Group: @retroactive ImageViewItem {
	public var imageName: String? {
		self.name
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
