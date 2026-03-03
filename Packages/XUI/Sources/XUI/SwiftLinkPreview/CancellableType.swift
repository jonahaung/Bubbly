//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

@objc
public protocol CancellableType {
    var isCancelled: Bool { get }
    func cancel()
}

public final class CancellableModel: NSObject, CancellableType, @unchecked Sendable {
    // Protect mutable state with a lock to make it concurrency-safe.
    private let lock = NSLock()
    private var _isCancelled: Bool = false

    public var isCancelled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _isCancelled
    }

    @objc public func cancel() {
        lock.lock()
        _isCancelled = true
        lock.unlock()
    }
}
