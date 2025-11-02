//
//  Models++.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 4/9/25.
//

import Foundation
import SwiftUI
import XUI
import Database
import ImageLoader

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
			return MediaType.png
		case .imageUploading:
			return MediaType.png
		case .video:
			return .video
		case .videoUploading:
			return .video
		case .link:
			return .data
		case nil:
			return nil
		}
	}
}
