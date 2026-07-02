import Foundation

public final class ProducerConsumerQueue<T> {
    private var buffer: [T?]
    private var head = 0
    private var tail = 0
    private var _count = 0
    private let lock = NSLock()
    private var semaphore = DispatchSemaphore(value: 0)

    public init(capacity: Int = 1024) {
        let cap = max(2, capacity.nextPowerOfTwo)
        buffer = [T?](repeating: nil, count: cap)
    }

    public func enqueue(_ item: T) {
        lock.lock()
        if _count == buffer.count { grow() }
        buffer[tail] = item
        tail = (tail + 1) & (buffer.count - 1)
        _count += 1
        lock.unlock()
        semaphore.signal()
    }

    public func dequeue() -> T {
        semaphore.wait()
        lock.lock()
        let item = buffer[head]!
        buffer[head] = nil
        head = (head + 1) & (buffer.count - 1)
        _count -= 1
        lock.unlock()
        return item
    }

    /// Non-blocking dequeue. Returns nil if empty.
    public func tryDequeue() -> T? {
        lock.lock()
        defer { lock.unlock() }
        // ✅ Use _count directly — calling isEmpty would re-acquire the lock (deadlock)
        guard _count > 0 else { return nil }
        let item = buffer[head]!
        buffer[head] = nil
        head = (head + 1) & (buffer.count - 1)
        _count -= 1
        return item
    }

    /// Removes all items and resets the semaphore to eliminate ghost signals.
    public func removeAll() {
        lock.lock()
        buffer = [T?](repeating: nil, count: buffer.count)
        head = 0
        tail = 0
        _count = 0
        // ✅ Replace semaphore entirely — draining it signal-by-signal would
        //    block if producers are concurrent; a fresh instance is safe.
        semaphore = DispatchSemaphore(value: 0)
        lock.unlock()
    }

    public var isEmpty: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _count == 0
    }

    /// Number of items currently in the queue.
    public var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return _count
    }

    private func grow() {
        let newCap = buffer.count * 2
        var newBuffer = [T?](repeating: nil, count: newCap)
        for i in 0 ..< _count {
            newBuffer[i] = buffer[(head + i) & (buffer.count - 1)]
        }
        buffer = newBuffer
        head = 0
        tail = _count
    }
}

private extension Int {
    var nextPowerOfTwo: Int {
        guard self > 1 else { return 2 }
        var v = self - 1
        // ✅ Cover all 64 bits
        v |= v >> 1
        v |= v >> 2
        v |= v >> 4
        v |= v >> 8
        v |= v >> 16
        v |= v >> 32
        return v + 1
    }
}

// MARK: - AsyncProducerConsumerQueue

public actor AsyncProducerConsumerQueue<T: Sendable> {
    private var buffer: [T] = []
    private var waiting: [CheckedContinuation<T?, Never>] = []
    private var isFinished = false

    public init() {}

    public func enqueue(_ item: T) {
        guard !isFinished else { return }
        if let waiter = waiting.first {
            waiting.removeFirst()
            waiter.resume(returning: item)
        } else {
            buffer.append(item)
        }
    }

    public func dequeue() async -> T? {
        if !buffer.isEmpty { return buffer.removeFirst() }
        if isFinished { return nil }
        return await withCheckedContinuation { cont in
            waiting.append(cont)
        }
    }

    public func finish() {
        isFinished = true
        for waiter in waiting { waiter.resume(returning: nil) }
        waiting.removeAll()
    }

    /// Removes buffered items and cancels all pending dequeuers with nil.
    /// The queue remains open for new enqueues unless `finish()` was called.
    public func removeAll() {
        buffer.removeAll()
        for waiter in waiting { waiter.resume(returning: nil) }
        waiting.removeAll()
    }

    /// Each call creates an independent consumer stream.
    /// Only use one stream per queue instance to avoid item loss.
    public nonisolated var stream: AsyncStream<T> {
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
