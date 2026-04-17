//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers

public protocol PhotoGalleryItem: Identifiable, Equatable {
    var galleryURL: URL? { get }
    var galleryTitle: String? { get }
    var id: String { get }
}

public struct PhotoGalleryView: View {
    private let items: [any PhotoGalleryItem]
    @State private var selection: String?
    private let title: String?
    @Environment(\.dismiss) private var dismiss

    public init(items: [any PhotoGalleryItem], title: String?, selection: String?) {
        self.items = items
        self.title = title
        self.selection = selection ?? ""
    }

    public var body: some View {
        VStack(spacing: 0) {
            topBar
            TabView(selection: $selection) {
                ForEach(items, id: \.id) { item in
                    Tab(value: item.id) {
                        PhotoGalleryCell(item)
                            .tag(item.id)
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            bottomBar
        }
    }

    private var topBar: some View {
        HStack {
            DismissButton(dismiss: dismiss)
            Spacer()
            shareButton
        }
        .padding()
    }

    private var bottomBar: some View {
        XPhotoPageControl(
            selection: .init(
                get: { selection ?? items.first?.id
                    ?? ""
                },
                set: { selection = $0 }
            ),
            items: items.map(\.id),
            size: 20
        )
        .padding()
    }

    @ViewBuilder private var shareButton: some View {
        let currentItem = items.first(where: { $0.id == selection })
        if
            let item = currentItem,
            let url = item.galleryURL,
            let data = try? Data(contentsOf: url),
            let uIImage = UIImage(data: data) {
            let image = Image(uiImage: uIImage)
            ShareLink(
                item: image,
                preview: SharePreview(item.galleryTitle ?? "", image: image)
            )
            .labelStyle(.iconOnly)
        }
    }
}
