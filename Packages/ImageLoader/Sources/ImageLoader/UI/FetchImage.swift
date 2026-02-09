// The MIT License (MIT)
// Copyright (c) 2015-2024 Alexander Grebenyuk (github.com/kean).

import Combine
import SwiftUI

@Observable
public final class FetchImage: Identifiable {
	public private(set) var result: Result<ImageResponse, Error>?
	public private(set) var imageContainer: ImageContainer?
	public private(set) var isLoading = false
	public var transaction = Transaction(animation: nil)
	public var progress: Progress {
		if _progress == nil {
			_progress = Progress()
		}
		return _progress!
	}

	private var _progress: Progress?

	@Observable
	public final class Progress {
		public internal(set) var completed: Int64 = 0
		public internal(set) var total: Int64 = 0
		public var fraction: Float {
			guard total > 0 else { return 0 }
			return min(1, Float(completed) / Float(total))
		}
	}

	public var priority: ImageRequest.Priority? {
		didSet { priority.map { imageTask?.priority = $0 } }
	}

	public var pipeline: ImagePipeline = .shared
	public var processors: [any ImageProcessing] = []
	public var onStart: ((ImageTask) -> Void)?
	public var onCompletion: ((Result<ImageResponse, Error>) -> Void)?

	private var imageTask: ImageTask?
	private var lastResponse: ImageResponse?
	private var cancellable: AnyCancellable?

	deinit {
		MainActor.assumeIsolated {
			imageTask?.cancel()
		}
	}

	public init() {}

	public func load(_ url: URL?) {
		load(url.map { ImageRequest(url: $0) })
	}

	public func load(_ request: ImageRequest?) {
		assert(Thread.isMainThread, "Must be called from the main thread")

		reset()

		guard var request else {
			handle(result: .failure(ImagePipeline.Error.imageRequestMissing))
			return
		}

		if !processors.isEmpty, request.processors.isEmpty {
			request.processors = processors
		}
		if let priority {
			request.priority = priority
		}

		if let image = pipeline.cache[request] {
			if image.isPreview {
				imageContainer = image
			} else {
				let response = ImageResponse(container: image, request: request, cacheType: .memory)
				handle(result: .success(response))
				return
			}
		}

		isLoading = true

		let task = pipeline.loadImage(
			with: request,
			progress: { [weak self] response, completed, total in
				guard let self else { return }
				if let response {
					withTransaction(transaction) {
						self.handle(preview: response)
					}
				} else {
					_progress?.completed = completed
					_progress?.total = total
				}
			},
			completion: { [weak self] result in
				guard let self else { return }
				withTransaction(transaction) {
					self.handle(result: result.mapError { $0 })
				}
			}
		)
		imageTask = task
		onStart?(task)
	}

	private func handle(preview: ImageResponse) {
		imageContainer = preview.container
	}

	private func handle(result: Result<ImageResponse, Error>) {
		isLoading = false
		imageTask = nil
		if case let .success(response) = result {
			imageContainer = response.container
		}
		self.result = result
		onCompletion?(result)
	}

	public func load(_ action: @escaping () async throws -> ImageResponse) {
		reset()
		isLoading = true

		let task = Task {
			do {
				let response = try await action()
				withTransaction(transaction) {
					handle(result: .success(response))
				}
			} catch {
				handle(result: .failure(error))
			}
		}

		cancellable = AnyCancellable { task.cancel() }
	}

	public func cancel() {
		imageTask?.cancel()
		imageTask = nil
		cancellable = nil
	}

	public func reset() {
		cancel()
		if isLoading { isLoading = false }
		if imageContainer != nil { imageContainer = nil }
		if result != nil { result = nil }
		if _progress != nil { _progress = nil }
		lastResponse = nil
	}
}
