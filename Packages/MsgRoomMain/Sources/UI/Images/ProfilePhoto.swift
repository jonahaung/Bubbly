//
//  ProfilePhoto.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 27/8/25.
//

import SwiftUI
import XUI
import Services

public struct ProfilePhoto: View {

	public typealias Item = any ImageViewItem

	let item: Item
	let size: AvatarSize
	let config: ImageViewConfig

	public init(_ item: Item, size: AvatarSize = .small, tapAction: ImageViewTapAction = .openPhotoViewer) {
		self.item = item
		self.size = size
		self.config = .init(
			size: size,
			processors: [.sticker()], tapAction: tapAction
		)
	}
	public
	var body: some View {
		ImageView(item, config: config)
			.background(.quinary)
			.clipShape(.circle)
	}
}
