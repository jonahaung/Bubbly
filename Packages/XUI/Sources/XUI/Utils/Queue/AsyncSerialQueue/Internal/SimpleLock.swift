//  SimpleLock.swift
//
//  Copyright © 2026 Aung Ko Min.
//

#if false
//
    //  SimpleLock.swift
//
//
    //  Created by Danny Sung on 6/5/24.
//

    import os
    import Foundation

    protocol SimpleLockInterface: Sendable {
        associatedtype Value

        init(initialState: Value)

        func withLockUnchecked<R>(_ body: (inout Value) throws -> R) rethrows -> R

        func withLock<R: Sendable>(_ body: @Sendable (inout Value) throws -> R) rethrows -> R
    }

    @propertyWrapper
    struct SimpleLock<Value: Sendable>: SimpleLockInterface {
        var wrappedValue: Value {
            get {
                withLock { $0 }
            }
            set {
                withLock { $0 = newValue }
            }
        }

        @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, visionOS 1.0, *)
        private var unfairLock: SimpleUnfairLock<Value>!

        private var semaphoreLock: SimpleLockSemaphore<Value>!

        init(initialState: Value) {
            if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, visionOS 1.0, *) {
                unfairLock = SimpleUnfairLock(initialState: initialState)
                semaphoreLock = nil
            } else {
                semaphoreLock = nil
                semaphoreLock = SimpleLockSemaphore(initialState: initialState)
            }
        }

        func withLockUnchecked<R>(_ body: (inout Value) throws -> R) rethrows -> R {
            if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, visionOS 1.0, *) {
                try unfairLock.withLockUnchecked(body)
            } else {
                try semaphoreLock.withLockUnchecked(body)
            }
        }

        func withLock<R: Sendable>(_ body: @Sendable (inout Value) throws -> R) rethrows -> R {
            if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, visionOS 1.0, *) {
                try unfairLock.withLock(body)
            } else {
                try semaphoreLock.withLock(body)
            }
        }

    }

    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, visionOS 1.0, *)
    final class SimpleUnfairLock<V: Sendable>: @unchecked Sendable, SimpleLockInterface {

        private var unfairLock: OSAllocatedUnfairLock<V>

        init(initialState: V) {
            unfairLock = .init(initialState: initialState)
        }

        func withLockUnchecked<R>(_ body: (inout V) throws -> R) rethrows -> R {
            try unfairLock.withLockUnchecked(body)
        }

        func withLock<R: Sendable>(_ body: @Sendable (inout V) throws -> R) rethrows -> R {
            try unfairLock.withLock(body)
        }

    }

    final class SimpleLockSemaphore<V>: @unchecked Sendable, SimpleLockInterface {
        private let semaphore: DispatchSemaphore
        private var value: V

        init(initialState: V) {
            value = initialState
            semaphore = DispatchSemaphore(value: 1)
        }

        func withLockUnchecked<R>(_ body: (inout V) throws -> R) rethrows -> R {
            semaphore.wait()
            defer { self.semaphore.signal() }

            return try body(&value)
        }

        func withLock<R: Sendable>(_ body: @Sendable (inout V) throws -> R) rethrows -> R {
            try withLockUnchecked(body)
        }
    }

#endif
