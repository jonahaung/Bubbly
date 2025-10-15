//
//  Atomic.swift
//  RoomRentalDemo
//
//  Created by Aung Ko Min on 20/1/23.
//

import Foundation

public final class Atomic<T: Sendable> {
    private var _value: T
    private let lock: os_unfair_lock_t

    public init(wrappedValue: T) {
        self._value = wrappedValue
        self.lock = .allocate(capacity: 1)
        self.lock.initialize(to: os_unfair_lock())
    }

    deinit {
        lock.deinitialize(count: 1)
        lock.deallocate()
    }

    public var wrappedValue: T {
        get {
            os_unfair_lock_lock(lock)
            defer { os_unfair_lock_unlock(lock) }
            return _value
        }
        set {
            os_unfair_lock_lock(lock)
            defer { os_unfair_lock_unlock(lock) }
            _value = newValue
        }
    }

    public func withLock<U>(_ closure: (inout T) -> U) -> U {
        os_unfair_lock_lock(lock)
        defer { os_unfair_lock_unlock(lock) }
        return closure(&_value)
    }
}
