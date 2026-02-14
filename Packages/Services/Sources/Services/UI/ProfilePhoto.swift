import Database
import SwiftUI
import XUI

public struct ProfilePhoto: View {
	let item: any ImageViewItem
	let config: ImageViewConfig

	public init(_ item: any ImageViewItem,
	            size: ImageSize = .small,
	            tapAction: ImageViewTapAction = .none)
	{
		self.item = item
		config = .init(
			size: size,
			processors: [], tapAction: tapAction
		)
	}

	public var body: some View {
		if let name = item.imageName {
			TextAvatarView(text: name)
				.frame(square: config.size.height)
				.clipShape(.circle)
		} else {
			ImageView(item, config: config)
				.clipShape(.circle)
				.equatable(by: item.remoteURL)
		}
	}
}
