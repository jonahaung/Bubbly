//  UnfairLock.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import Foundation

public final class UnfairLock {
    private let pointer: os_unfair_lock_t
    public init() {
        pointer = .allocate(capacity: 1)
        pointer.initialize(to: os_unfair_lock())
    }

    deinit {
        self.pointer.deinitialize(count: 1)
        self.pointer.deallocate()
    }

    public func lock() {
        os_unfair_lock_lock(pointer)
    }

    public func unlock() {
        os_unfair_lock_unlock(pointer)
    }

    public func tryLock() -> Bool {
        os_unfair_lock_trylock(pointer)
    }

    @discardableResult
    @inlinable
    public func execute<T>(_ action: () -> T) -> T {
        lock()
        defer { self.unlock() }
        return action()
    }

    @discardableResult
    @inlinable
    public func tryExecute<T>(_ action: () throws -> T) throws -> T {
        try execute { Result(catching: action) }.get()
    }
}
