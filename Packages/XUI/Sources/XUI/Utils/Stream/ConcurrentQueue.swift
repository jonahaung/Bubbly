import Foundation

public class ConcurrentQueue<T> {
	let lock = Lock()
	let second: Double = 1_000_000

	var queue: Queue<T>
	let timeSleep: Double

	public init(timeSleep: Double = 0.001) {
		queue = Queue<T>()
		self.timeSleep = timeSleep
	}

	public var isEmpty: Bool { queue.isEmpty }
	public var count: Int { queue.count }
	public var front: T? { queue.front }

	public func put(_ element: T) throws {
		try put(element, timeout: nil)
	}

	public func put(_ element: T, timeout: Double?) throws {
		let timeStart = Date()

		while true {
			do {
				try lock.aquire {
					try queue.put(element)
				}
				break
			} catch QueueError.full {
				usleep(useconds_t(timeSleep * second))
			}

			if let timeout = timeout, timeStart.timeIntervalSinceNow.magnitude >= timeout {
				throw QueueError.full
			}
		}
	}

	public func get() throws -> T {
		return try get(timeout: nil)
	}

	public func get(timeout: Double?) throws -> T {
		let timeStart = Date()
		var output: T?

		while true {
			do {
				try lock.aquire {
					output = try queue.get()
				}
				if let result = output {
					return result
				} else {
					throw QueueError.empty
				}
			} catch QueueError.empty {
				usleep(useconds_t(timeSleep * second))
			}
			if let timeout = timeout, timeStart.timeIntervalSinceNow.magnitude >= timeout {
				throw QueueError.empty
			}
		}
	}
}

public final class ThreadSafeQueue<T> {
	private struct PrivateQueue {
		var array = [T?]()
		var head = 0
	}

	private var queue = PrivateQueue()
	private let maxSize: Int?
	private var lock = os_unfair_lock()
	private let spaceAvailable = DispatchSemaphore(value: 0)
	private let spaceFree: DispatchSemaphore?

	public init(maxSize: Int? = nil) {
		self.maxSize = maxSize
		self.spaceFree = maxSize != nil ? DispatchSemaphore(value: maxSize!) : nil
	}

	public var isEmpty: Bool {
		os_unfair_lock_lock(&lock)
		defer { os_unfair_lock_unlock(&lock) }
		return queue.array.count - queue.head == 0
	}

	public var count: Int {
		os_unfair_lock_lock(&lock)
		defer { os_unfair_lock_unlock(&lock) }
		return queue.array.count - queue.head
	}

	public func put(_ element: T, timeout: DispatchTime = .distantFuture) throws {
		// Wait for available space if bounded
		if let spaceFree = spaceFree {
			guard case .success = spaceFree.wait(timeout: timeout) else {
				throw QueueError.full
			}
		}

		os_unfair_lock_lock(&lock)
		defer { os_unfair_lock_unlock(&lock) }

		queue.array.append(element)
		spaceAvailable.signal()
	}

	public func get(timeout: DispatchTime = .distantFuture) throws -> T {
		// Wait for available items
		guard case .success = spaceAvailable.wait(timeout: timeout) else {
			throw QueueError.empty
		}

		os_unfair_lock_lock(&lock)
		defer { os_unfair_lock_unlock(&lock) }

		guard queue.head < queue.array.count, let element = queue.array[queue.head] else {
			// This should theoretically never happen
			spaceAvailable.signal() // Restore the semaphore count
			throw QueueError.empty
		}

		queue.array[queue.head] = nil
		queue.head += 1

		// Compact if too much wasted space
		let percentage = Double(queue.head)/Double(queue.array.count)
		if queue.array.count > 50 && percentage > 0.25 {
			queue.array.removeFirst(queue.head)
			queue.head = 0
		}

		spaceFree?.signal()
		return element
	}

	public var front: T? {
		os_unfair_lock_lock(&lock)
		defer { os_unfair_lock_unlock(&lock) }
		return (queue.array.count - queue.head) > 0 ? queue.array[queue.head] : nil
	}
}
