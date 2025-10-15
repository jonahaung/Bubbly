//
//  AtomicWrite.swift
//  XUI
//
//  Created by Aung Ko Min on 23/6/25.
//

import Foundation
@propertyWrapper
public struct AtomicWrite<Value> {

    // TODO: Faster version with os_unfair_lock?

    let queue = DispatchQueue(label: "Atomic write access queue", attributes: .concurrent)
    var value: Value

    public init(wrappedValue: Value) {
        self.value = wrappedValue
    }

    public var wrappedValue: Value {
        get {
            return queue.sync { value }
        }
        set {
            queue.sync(flags: .barrier) { value = newValue }
        }
    }

    /// Atomically mutate the variable (read-modify-write).
    ///
    /// - parameter action: A closure executed with atomic in-out access to the wrapped property.
    public mutating func mutate(_ mutation: (inout Value) throws -> Void) rethrows {
        return try queue.sync(flags: .barrier) {
            try mutation(&value)
        }
    }
}
