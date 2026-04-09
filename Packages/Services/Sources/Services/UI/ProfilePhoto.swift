//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import Database
import SwiftUI
import XUI

public struct ProfilePhoto: View {
    let item: any ImageViewItem
    let config: ImageViewConfig

    public init(
        _ item: any ImageViewItem,
        size: ImageSize = .small,
        tapAction: ImageViewTapAction = .none
    ) {
        self.item = item
        config = .init(
            size: size,
            processors: [], tapAction: tapAction
        )
    }

	public init(
		_ item: any ImageViewItem,
		config: ImageViewConfig
	) {
		self.item = item
		self.config = config
	}

    public var body: some View {
        ImageView(item, config: config)
            .clipShape(.circle)
            .equatable(by: item.remoteURL)
    }
}
