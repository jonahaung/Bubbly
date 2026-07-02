// © 2026 Aung Ko Min

import Database
import SwiftUI
import XUI

public struct ProfilePhoto: View {
    let item: any ImageViewItem
    let config: ImageViewConfig

    public init(
        _ item: any ImageViewItem,
        size: ImageSize = .small,
        tapAction: ImageViewTapAction = .none,
    ) {
        self.item = item
        config = .init(
            size: size,
            processors: [.circle()], tapAction: tapAction,
        )
    }

    public init(
        _ item: any ImageViewItem,
        config: ImageViewConfig,
    ) {
        self.item = item
        self.config = config
    }

    public var body: some View {
        if item.remoteURL == nil {
            if let text = item.imageName {
               TextAvatarView(text: text)
                    .frame(square: config.size.height)
            }
        } else {
            ImageView(item, config: config)
                .clipShape(.circle)
                .equatable(by: item.remoteURL)
        }
        
    }
}
