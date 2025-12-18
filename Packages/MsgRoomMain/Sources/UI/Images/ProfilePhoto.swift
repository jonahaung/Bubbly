//
//  ProfilePhoto.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 27/8/25.
//

import Database
import Services
import SwiftUI
import XUI

public struct ProfilePhoto: View {

	let item: any ImageViewItem
	let config: ImageViewConfig

	public init(
		_ item: any ImageViewItem,
		size: ImageSize = .small,
		tapAction: ImageViewTapAction = .openPhotoViewer
	) {
		self.item = item
		config = .init(
			size: size,
			processors: [], tapAction: tapAction
		)
	}

	public var body: some View {
		ImageView(item, config: config)
			.clipShape(.circle)
			.equatable(by: item.remoteURL)
	}
}
