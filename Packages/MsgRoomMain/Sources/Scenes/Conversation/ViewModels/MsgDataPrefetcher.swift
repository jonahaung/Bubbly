//
//  MsgDataPrefetcher.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 23/9/25.
//

import Foundation
import Database
import Services
import SwiftUI
import XUI

public protocol AsyncFetcherItem: Sendable, Identifiable {
	static var empty: Self { get }
}
final class AsyncFetcherOperation<T: AsyncFetcherItem>: Operation, @unchecked Sendable  where T.ID: Sendable {
	let identifier: T.ID
	private(set) var fetchedData: T?

	init(identifier: T.ID) {
		self.identifier = identifier
	}

	override func main() {
		Thread.sleep(until: Date().addingTimeInterval(1))
		guard !isCancelled else { return }
		fetchedData = T.empty
	}
}

// MARK: - Fetcher

final class AsyncFetcher<T: AsyncFetcherItem>: @unchecked Sendable where T.ID: Sendable {
	
	private let serialQueue: OperationQueue
	private let fetchQueue: OperationQueue

	private let cache = SafeStorage(stored: [T.ID: T]())
	private var completionHandlers: [T.ID: [@Sendable (T?) -> Void]] = [:]

	init() {
		serialQueue = OperationQueue()
		serialQueue.maxConcurrentOperationCount = 1

		fetchQueue = OperationQueue()
		fetchQueue.qualityOfService = .userInitiated
	}

	// MARK: Public API

	func fetchAsync(_ identifier: T.ID, completion: (@Sendable (T?) -> Void)? = nil) {
		serialQueue.addOperation {
			if let completion {
				self.completionHandlers[identifier, default: []].append(completion)
			}
			self.enqueueFetch(for: identifier)
		}
	}

	func fetchedData(for identifier: T.ID) -> T? {
		cache.get()[identifier]
	}

	func cancelFetch(_ identifier: T.ID) {
		serialQueue.addOperation {
			self.fetchQueue.isSuspended = true
			defer { self.fetchQueue.isSuspended = false }

			self.operation(for: identifier)?.cancel()
			self.completionHandlers[identifier] = nil
		}
	}

	// MARK: Private Helpers

	private func enqueueFetch(for identifier: T.ID) {
		// Already scheduled or in cache?
		if operation(for: identifier) != nil { return }

		if let cached = fetchedData(for: identifier) {
			invokeCompletionHandlers(for: identifier, with: cached)
			return
		}

		let operation = AsyncFetcherOperation<T>(identifier: identifier)

		operation.completionBlock = { [weak operation, weak self] in
			guard let self, let data = operation?.fetchedData else { return }
			self.cache.apply { dic in
				dic[identifier] = data
			}
			self.serialQueue.addOperation {
				self.invokeCompletionHandlers(for: identifier, with: data)
			}
		}

		fetchQueue.addOperation(operation)
	}

	private func operation(for identifier: T.ID) -> AsyncFetcherOperation<T>? {
		fetchQueue.operations
			.compactMap { $0 as? AsyncFetcherOperation }
			.first { !$0.isCancelled && $0.identifier == identifier }
	}

	private func invokeCompletionHandlers(for identifier: T.ID, with data: T) {
		let handlers = completionHandlers.removeValue(forKey: identifier) ?? []
		handlers.forEach { $0(data) }
	}
}
