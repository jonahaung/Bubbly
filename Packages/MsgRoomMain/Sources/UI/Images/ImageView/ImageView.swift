//
//  ImageView.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 4/9/25.
//

import SwiftUI
import ImageLoader
import XUI
import Services

public struct ImageView: View {

	public typealias Item = any ImageViewItem

	@State private var progress: ImageTask.Progress?
	@State private var error: Error?
	@State private var manager: ImageViewManager
	@State private var fetchImage = FetchImage()

	private let config: ImageViewConfig

	public init(_ item: Item, config: ImageViewConfig) {
		self.manager = ImageViewManager(item: item)
		self.config = config
	}

	public var body: some View {
		ZStack {
			config.backgroundColor?.layoutPriority(-1)
			if manager.isLocallyCached() {
				if let image = manager.image {
					imageView(for: image)
						.transition(.scale(scale: 0.0, anchor: .center).animation(.interactiveSpring))
				} else {
					ProgressView().controlSize(.mini)
						.task {
							await manager.onAppear()
						}
				}
			} else {
				ZStack {
					if let image = fetchImage.image{
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
				.onAppear {
					guard fetchImage.imageContainer?.image == nil else { return }
					if fetchImage.isLoading {
						return
					}
					let transaction: Transaction = {
						var transaction = Transaction(animation: .interactiveSpring)
						transaction.dismissBehavior = .destructive
						transaction.disablesAnimations = false
						return transaction
					}()
					fetchImage.processors = config.processors
					fetchImage.transaction = transaction
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
		.frame(size: config.size?.size)
	}
}

extension ImageView {
	@ViewBuilder
	func imageView(for image: Image) -> some View {
		switch config.tapAction {
		case .openPhotoViewer:
			image
				.resizable()
				.aspectRatio(contentMode: (config.size?.width == nil && config.size?.height == nil) ? .fit : .fill)
				.sheetWithZoomTransition { imagerViewerScene }
				.equatable(by: manager.item.imageID)
		case .custom(let action):
			image
				.resizable()
				.aspectRatio(contentMode: (config.size?.width == nil && config.size?.height == nil) ? .fit : .fill)
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
		if let progress {
			ProgressView(value: CGFloat(progress.completed), total: CGFloat(progress.total))
				.progressViewStyle(.circular)
				.controlSize(.mini)
		} else {
			ProgressView().controlSize(.mini)
		}
	}

	var imagerViewerScene: some View {
		PhotoViewer(.init(
			url: MediaManager.shared.url(for: manager.item.imageID, manager.item.type).absoluteString,
			type: .photo,
			identifier: manager.item.imageID
		))
	}

	var processors: [ImageProcessing] {
		var array: [ImageProcessing] = []
		if let size = config.size {
			if let w = size.width, let h = size.height {
				array.append(.resize(size: .init(width: w, height: h)))
			} else if let w = size.width {
				array.append(.resize(width: w))
			} else if let h = size.height {
				array.append(.resize(height: h))
			}
		}
		return array + config.processors
	}
}
