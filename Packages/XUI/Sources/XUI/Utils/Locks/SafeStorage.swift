//
//  SafeStorage.swift
//  XUI
//
//  Created by Aung Ko Min on 13/10/25.
//

import Foundation

public final class SafeStorage<T>: @unchecked Sendable {
    private let lock = NSRecursiveLock()
    private var stored: T

    public init(stored: T) {
        self.stored = stored
    }

    public func get() -> T {
        lock.lock()
        defer { self.lock.unlock() }
        return stored
    }

    public func set(stored: T) {
        lock.lock()
        defer { self.lock.unlock() }
        self.stored = stored
    }

    public func apply<R>(block: (inout T) -> R) -> R {
        lock.lock()
        defer { self.lock.unlock() }
        return block(&stored)
    }
}
