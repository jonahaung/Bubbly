//
//  Models++.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 4/9/25.
//

import Foundation
import Services
import SwiftUI
import XUI
import Database
import ImageLoader

extension ContactSnapshot: ImageViewItem {
	public var imageID: String {
		url.lastPathComponent
	}

	public var url: URL {
		.init(string: photoURL) ?? DemoImages.demoPhotosURLs.random()!
	}

	public var type: Services.MediaType {
		.png
	}
}

extension AvatarSize: ImageSize {
	public var width: CGFloat? {
		value
	}
	public var height: CGFloat? {
		value
	}
}

extension ConversationSnapshot: ImageViewItem {
	public var imageID: String {
		url.lastPathComponent
	}
	public var url: URL {
		.init(string: photoURL ?? "") ?? DemoImages.demoPhotosURLs.random()!
	}

	public var type: Services.MediaType {
		.png
	}
}
