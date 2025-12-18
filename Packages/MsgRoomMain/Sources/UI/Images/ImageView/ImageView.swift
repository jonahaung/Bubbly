//
//  ImageView.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 4/9/25.
//

import Database
import ImageLoader
import Services
import SwiftUI
import XUI

public struct ImageView: View {
	public typealias Item = any ImageViewItem
	@State private var error: Error?
	@State private var manager: ImageViewManager
	@State private var fetchImage = FetchImage()

	private let config: ImageViewConfig

	public init(_ item: any ImageViewItem, config: ImageViewConfig) {
		manager = ImageViewManager(item: item)
		self.config = config
	}

	public var body: some View {
		ZStack {
			config.backgroundColor?.layoutPriority(-1)
			if let image = manager.image {
				imageView(for: image)
			} else {
				if manager.isLocallyCached() {
					progressView
						.task {
							manager.image = config.size == .original ? manager.item
								.image() : manager.item
								.thumbnailImage()
						}
				} else {
					ZStack {
						if fetchImage.isLoading {
							progressView
						} else {
							if let image = fetchImage.image {
								imageView(for: image)
							} else {
								switch fetchImage.result {
								case .success(let response):
									imageView(for: response.image)
								case .failure:
									SystemImageWithShape(.exclamationmark, .circle(.color(.red)))
								case .none:
									ProgressView().controlSize(.mini)
								}
							}
						}
					}
					.onAppear {
						guard fetchImage.imageContainer?.image == nil else { return }
						if fetchImage.isLoading {
							return
						}
						fetchImage.processors = config.processors
						fetchImage.transaction = .withoutAnimation
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
						config.size.value == nil) ? .fit : .fill
				)
				.sheetWithZoomTransition { imagerViewerScene }
				.equatable(by: manager.item.imageID)
		case .custom(let action):
			image
				.resizable()
				.aspectRatio(contentMode: config.size.value == nil ? .fit : .fill)
				.onTapGesture(perform: action)
				.equatable(by: manager.item.imageID)
		}
	}

	@ViewBuilder
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

	@ViewBuilder var imagerViewerScene: some View {
		if let url = manager.item.file()?.url {
			PhotoViewer(
				.init(
					url: url.absoluteString,
					type: .photo,
					identifier: manager.item.imageID
				)
			)
		}
	}

	var processors: [ImageProcessing] {
		var array: [ImageProcessing] = []
		if let value = config.size.value {
			array.append(.resize(width: value))
		}
		return array + config.processors
	}
}
