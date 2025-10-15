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
	private let config: ImageViewConfig

	public init(_ item: Item, config: ImageViewConfig) {
		self.manager = ImageViewManager(item: item)
		self.config = config
	}

	public var body: some View {
		ZStack {
			config.backgroundColor
			LazyImage(url: manager.getURL()) { state in
				switch state.result {
				case .success(let image):
					imageView(for: image.image)
				case .failure:
					SystemImage(.exclamationmarkCircleFill)
						.symbolRenderingMode(.multicolor)
				case .none:
					progressView
				}
			}
			.processors(processors)
			.pipeline(.shared)
			.onCompletion { [self] result in
				if case .success(let response) = result {
					saveImage(response.image)

				}
			}
		}
		.frame(width: config.size?.width, height: config.size?.height)
	}

	private func saveImage(_ uiImage: UIImage) {
		Task {
			do {
				try await manager.saveImage(uiImage)
			} catch {
				self.error = error
			}
		}
	}
}

extension ImageView {

	@ViewBuilder
	func imageView(for uiImage: UIImage) -> some View {
		let image = Image(uiImage: uiImage)
			.resizable()
			.aspectRatio(contentMode: (config.size?.width == nil && config.size?.height == nil) ? .fit : .fill)

		switch config.tapAction {
		case .openPhotoViewer:
			image.sheetWithZoomTransition { imagerViewerScene }
		case .custom(let action):
			image.onTapGesture(perform: action)
		}
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
			url: MediaManager.shared.url(for: manager.item.id, manager.item.type).absoluteString,
			type: .photo,
			identifier: manager.item.id
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
