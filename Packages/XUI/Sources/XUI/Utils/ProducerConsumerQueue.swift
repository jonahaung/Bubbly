import Foundation

public final class ProducerConsumerQueue<T> {
	private var buffer: [T?]
	private var head = 0
	private var tail = 0
	private var count = 0
	private let lock = NSLock()
	private let semaphore = DispatchSemaphore(value: 0)

	public init(capacity: Int = 1024) {
		// Round up capacity to nearest power of 2 for efficient wrapping
		let cap = max(2, capacity.nextPowerOfTwo)
		buffer = [T?](repeating: nil, count: cap)
	}

	/// Adds an item to the end of the queue and signals any waiting consumer.
	public func enqueue(_ item: T) {
		lock.lock()
		if count == buffer.count { // grow if full
			grow()
		}
		buffer[tail] = item
		tail = (tail + 1) & (buffer.count - 1)
		count += 1
		lock.unlock()
		semaphore.signal()
	}

	/// Removes and returns the item at the front of the queue, blocking if empty.
	public func dequeue() -> T {
		semaphore.wait() // block until available
		lock.lock()
		let item = buffer[head]!
		buffer[head] = nil
		head = (head + 1) & (buffer.count - 1)
		count -= 1
		lock.unlock()
		return item
	}

	/// Non-blocking dequeue. Returns nil if empty.
	public func tryDequeue() -> T? {
		lock.lock()
		defer { lock.unlock() }
		guard !isEmpty else { return nil }
		let item = buffer[head]!
		buffer[head] = nil
		head = (head + 1) & (buffer.count - 1)
		count -= 1
		return item
	}

	/// Removes all items from the queue.
	public func removeAll() {
		lock.lock()
		buffer = [T?](repeating: nil, count: buffer.count)
		head = 0
		tail = 0
		count = 0
		lock.unlock()
		// ⚠️ Note: semaphore may still have pending signals
	}

	/// Whether the queue is empty.
	public var isEmpty: Bool {
		lock.lock()
		let result = (count == 0)
		lock.unlock()
		return result
	}

	/// Number of items in the queue.
	public var countItems: Int {
		lock.lock()
		let result = count
		lock.unlock()
		return result
	}

	private func grow() {
		let newCap = buffer.count * 2
		var newBuffer = [T?](repeating: nil, count: newCap)
		for i in 0 ..< count {
			newBuffer[i] = buffer[(head + i) & (buffer.count - 1)]
		}
		buffer = newBuffer
		head = 0
		tail = count
	}
}

private extension Int {
	var nextPowerOfTwo: Int {
		var v = self
		v -= 1
		v |= v >> 1
		v |= v >> 2
		v |= v >> 4
		v |= v >> 8
		v |= v >> 16
		return v + 1
	}
}

/// A thread-safe async producer-consumer queue with both `AsyncStream` and `dequeue()` support.
public actor AsyncProducerConsumerQueue<T: Sendable> {
	private var buffer: [T] = []
	private var waiting: [CheckedContinuation<T?, Never>] = []
	private var isFinished = false

	public init() {}

	/// Enqueues an item into the queue.
	public func enqueue(_ item: T) {
		if let waiter = waiting.first {
			waiting.removeFirst()
			waiter.resume(returning: item)
		} else {
			buffer.append(item)
		}
	}

	/// Dequeues the next item, suspending if necessary.
	/// Returns `nil` if the queue is finished and empty.
	public func dequeue() async -> T? {
		if !buffer.isEmpty {
			return buffer.removeFirst()
		}
		if isFinished {
			return nil
		}
		return await withCheckedContinuation { (cont: CheckedContinuation<T?, Never>) in
			waiting.append(cont)
		}
	}

	/// Finishes the queue, signaling no more items will be sent.
	/// All pending dequeuers will receive `nil`.
	public func finish() {
		isFinished = true
		for waiter in waiting {
			waiter.resume(returning: nil)
		}
		waiting.removeAll()
	}

	/// Convenience: An async sequence interface for iterating.
	nonisolated public var stream: AsyncStream<T> {
		AsyncStream { continuation in
			Task {
				while let value = await self.dequeue() {
					continuation.yield(value)
				}
				continuation.finish()
			}
		}
	}
}

public extension AsyncProducerConsumerQueue {
	/// Removes all buffered items and cancels all pending dequeuers.
	/// Waiting dequeuers will resume with `nil`.
	func removeAll() {
		buffer.removeAll()
		for waiter in waiting {
			waiter.resume(returning: nil)
		}
		waiting.removeAll()
	}
}
