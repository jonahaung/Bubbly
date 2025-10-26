//
//  TaskEvent.swift
//  XUI
//
//  Created by Aung Ko Min on 20/10/25.
//

import Foundation

public enum TaskEvent<Response> {
    case progress(Double)
    case preview(Response)
    case completed(Response)
    case fileSaved(URL)
    case fileLoaded(URL)
}

public actor AsyncTaskActor<Response: Sendable> {

    public nonisolated let id = UUID()
    private var task: Task<Response, Error>?
    private var isCancelled = false

    private var eventsContinuation: AsyncStream<TaskEvent<Response>>.Continuation?
    private var resultContinuation: CheckedContinuation<Response, Error>?

	public init() {
		Task { [weak self] in
			guard let self else { return }
			await self.startTask()
		}
	}
}

private extension AsyncTaskActor {
    private func startTask() {
        task = Task { [weak self] in
            guard let self else { throw CancellationError() }

            return try await withTaskCancellationHandler {
                let result = try await self.perform()
                await self.finish(with: result)
                return result
            } onCancel: {
                Task { await self.cancel() }
            }
        }
    }
}

public extension AsyncTaskActor {
    var result: Response {
        get async throws {
            try await withTaskCancellationHandler {
                guard let task else { throw CancellationError() }
                return try await task.value
            } onCancel: {
                Task { await cancel() }
            }
        }
    }
}

public extension AsyncTaskActor {
    var events: AsyncStream<TaskEvent<Response>> {
        AsyncStream { continuation in
            self.eventsContinuation = continuation
        }
    }

    func sendProgress(_ value: Double) {
        eventsContinuation?.yield(.progress(value))
    }

    func sendPreview(_ response: Response) {
        eventsContinuation?.yield(.preview(response))
    }

    func finish(with response: Response) {
        eventsContinuation?.yield(.completed(response))
        eventsContinuation?.finish()
        resultContinuation?.resume(returning: response)
    }
}

public extension AsyncTaskActor {
    func cancel() {
        guard !isCancelled else { return }
        isCancelled = true

        task?.cancel()
        eventsContinuation?.finish()
        resultContinuation?.resume(throwing: CancellationError())
    }
}

public extension AsyncTaskActor {

    /// Save Data to file on a background thread
    func saveFile(_ data: Data, to url: URL) async throws {
        try await Task.detached(priority: .utility) {
            try data.write(to: url, options: .atomic)
        }.value

        eventsContinuation?.yield(.fileSaved(url))
    }

    /// Load Data from file on a background thread
    func loadFile(from url: URL) async throws -> Data {
        let data = try await Task.detached(priority: .utility) {
            try Data(contentsOf: url)
        }.value

        eventsContinuation?.yield(.fileLoaded(url))
        return data
    }
}

// MARK: - Override this for real work
public extension AsyncTaskActor {
    @discardableResult
    func perform() async throws -> Response {
        fatalError("Override perform() in subclass.")
    }
}

/*
final class ImageSaveTask: AsyncTaskActor<URL> {

	private let imageData: Data
	private let fileURL: URL

	init(imageData: Data, fileURL: URL) {
		self.imageData = imageData
		self.fileURL = fileURL
		super.init()
	}

	override func perform() async throws -> URL {
		await sendProgress(0.1)
		try await saveFile(imageData, to: fileURL)
		await sendProgress(1.0)
		return fileURL
	}
}

// Usage:
let task = ImageSaveTask(imageData: data, fileURL: destinationURL)

Task {
	for await event in await task.events {
		print("Event →", event)
	}
}

Task {
	let fileURL = try await task.result
	print("✅ File saved to:", fileURL)
}
*/
