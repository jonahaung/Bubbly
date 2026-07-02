// © 2026 Aung Ko Min

import Database
import ImageLoader
import SwiftUI
import XUI

// MARK: - ImageView

public struct ImageView: View {
    public typealias Item = any ImageViewItem
    @State private var manager: ImageViewManager
    @State private var fetchImage: FetchImage = .init()

    private let config: ImageViewConfig

    public init(_ item: any ImageViewItem, config: ImageViewConfig) {
        manager = ImageViewManager(item: item)
        self.config = config
    }

    public var body: some View {
        ZStack {
            if let image = manager.image {
                imageView(for: image)
            } else {
                if manager.isLocallyCached() {
                    progressView
                        .task {
                            manager.loadLocalImage(isThumbnil: config.size != .original)
                        }
                } else {
                    ZStack {
                        if fetchImage.isLoading {
                            progressView
                        } else {
                            if let image = fetchImage.image {
                                imageView(for: image)
                            }
                        }
                    }
                    .onAppear {
                        guard fetchImage.imageContainer?.image == nil else {
                            return
                        }

                        if fetchImage.isLoading {
                            return
                        }
                        fetchImage.processors = config.processors
                        fetchImage.pipeline = .shared
                        fetchImage.onStart = manager.onStart
                        fetchImage.onCompletion = manager.onCompletion(_:)
                        fetchImage.load(manager.getURL())
                    }
                    .onDisappear {
                        fetchImage.cancel()
                    }
                }
            }
        }
        .frame(square: config.size.value)
        .fixedSize()
    }
}

extension ImageView {
    @ViewBuilder
    func imageView(for image: Image) -> some View {
        switch config.tapAction {
        case .openPhotoViewer:
            image
                .resizable()
                .aspectRatio(
                    contentMode: (
                        config.size.value == nil,
                    ) ? .fit : .fill,
                )
                .sheetWithZoomTransition { imagerViewerScene }
                .equatable(by: manager.item.imageID)
        case let .custom(action):
            image
                .resizable()
                .aspectRatio(contentMode: config.size.value == nil ? .fit : .fill)
                .onTapGesture(perform: action)
                .equatable(by: manager.item.imageID)
        case .none:
            image
                .resizable()
                .aspectRatio(contentMode: config.size.value == nil ? .fit : .fill)
        }
    }

    func imageView(for uiImage: UIImage) -> some View {
        imageView(for: Image(uiImage: uiImage))
    }

    @ViewBuilder
    var progressView: some View {
        if let progress = manager.progress {
            ProgressView(value: CGFloat(progress.completed), total: CGFloat(progress.total))
                .progressViewStyle(.circular)
                .controlSize(.mini)
        } else {
            ProgressView().controlSize(.mini)
        }
    }

    var imagerViewerScene: some View {
        PhotoGalleryView(
            items: [manager.item],
            title: manager.item.fileName(),
            selection: manager
                .item.id,
        )
    }

    var processors: [ImageProcessing] {
        var array = [ImageProcessing]()
        if let value = config.size.value {
            array.append(.resize(width: value))
        }
        return array + config.processors
    }
}
