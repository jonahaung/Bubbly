//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import ImageLoader
import SwiftUI

public struct PhotoGalleryCell: View {
    private let item: any PhotoGalleryItem
    @Environment(\.dismiss) private var dismiss

    public init(_ item: any PhotoGalleryItem, title _: String = "") {
        self.item = item
    }

    public var body: some View {
        LazyImage(url: item.galleryURL, transaction: .withAnimation()) { state in
            switch state.result {
            case let .success(success):
                Image(uiImage: success.image)
                    .resizable()
                    .scaledToFit()
                    .zoomable()
            case let .failure(failure):
                ContentUnavailableView {
                    Text("Error")
                } description: {
                    Text(failure.localizedDescription)
                }
            case .none:
                ProgressView().controlSize(.mini)
            }
        }
    }
}
