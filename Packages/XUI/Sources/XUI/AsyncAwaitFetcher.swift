import Foundation

public protocol AsyncFetchingItem: Sendable {
	associatedtype ID: Hashable & Sendable
	static func performFetch(for id: ID) async throws -> Self
}

public actor AsyncAwaitFetcher<Item: AsyncFetchingItem>: Sendable {
	private var cache = [Item.ID: Item]()
	private var tasks: [Item.ID: Task<Item, Error>] = [:]

	public init() {}

	@discardableResult
	public func fetch(_ id: Item.ID) async throws -> Item {
		if let cached = cache[id] {
			return cached
		}
		try await Task.sleep(seconds: 2)
		if let inFlight = tasks[id] {
			return try await inFlight.value
		}
		let task = Task<Item, Error> {
			defer { Task { self.clearTask(for: id) } }
			let data = try await Item.performFetch(for: id)
			cache[id] = data
			return data
		}
		tasks[id] = task
		return try await task.value
	}

	public func fetchedData(for id: Item.ID) -> Item? {
		cache[id]
	}

	public func cancelFetch(_ id: Item.ID) {
		tasks[id]?.cancel()
		tasks[id] = nil
	}

	private func clearTask(for id: Item.ID) {
		tasks[id] = nil
	}
}

public actor FetcherPool {
	private var storage: [ObjectIdentifier: Any] = [:]
	public static let shared = FetcherPool()

	public func fetcher<Item: AsyncFetchingItem>(of type: Item.Type) -> AsyncAwaitFetcher<Item> {
		let key = ObjectIdentifier(type)
		if let existing = storage[key] as? AsyncAwaitFetcher<Item> {
			return existing
		}
		let new = AsyncAwaitFetcher<Item>()
		storage[key] = new
		return new
	}
}
