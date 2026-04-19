//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import Foundation

public final class SafeStorage<T> {
    private let lock = NSRecursiveLock()
    private var stored: T

    public init(_ stored: T) {
        self.stored = stored
    }

    private func get() -> T {
        lock.lock()
        defer { self.lock.unlock() }
        return stored
    }
    
    private func set(stored: T) {
        lock.lock()
        defer { self.lock.unlock() }
        self.stored = stored
    }
    
    public var value: T {
        get { self.get() }
        set { self.set(stored: newValue) }
    }

    public func apply<R>(block: (inout T) -> R) -> R {
        lock.lock()
        defer { self.lock.unlock() }
        return block(&stored)
    }
}
