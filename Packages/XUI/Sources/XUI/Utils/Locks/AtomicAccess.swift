//
//  AtomicAccess.swift
//  XUI
//
//  Created by Aung Ko Min on 26/11/24.
//
import Foundation

public final class AtomicAccess<Value> {
    private var value: Value
    private let lock = NSLock()

    public init(_ value: Value) {
        self.value = value
    }
    public func access<T>(_ keyPath: KeyPath<Value, T>) -> T {
        lock.lock()
        defer { lock.unlock() }
        return value[keyPath: keyPath]
    }
    public func access<T>(_ accessing: (Value) throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try accessing(value)
    }
    public func mutate(_ newValue: Value) {
        value = newValue
    }
    public func mutate(_ mutation: (inout Value) throws -> Void) rethrows {
        lock.lock()
        defer { lock.unlock() }
        try mutation(&value)
    }
}
