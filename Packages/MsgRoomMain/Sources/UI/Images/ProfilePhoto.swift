//
//  ProfilePhoto.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 27/8/25.
//

import SwiftUI
import XUI
import Services
import Database

extension AvatarSize: ImageSize { }

public struct ProfilePhoto: View {

	public typealias Item = any ImageViewItem

	let item: Item
	let size: AvatarSize
	let config: ImageViewConfig

	public init(_ item: Item, size: AvatarSize = .small, tapAction: ImageViewTapAction = .openPhotoViewer) {
		self.item = item
		self.size = size
		self.config = .init(
			size: size as! ImageSize,
			processors: [.sticker()], tapAction: tapAction
		)
	}
	public var body: some View {
		ImageView(item, config: config)
			.background(Color.systemGray6)
			.clipShape(.circle)
	}
}
