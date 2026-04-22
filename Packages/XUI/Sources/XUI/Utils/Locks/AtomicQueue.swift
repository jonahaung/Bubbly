//  AtomicQueue.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import Foundation

@propertyWrapper
public struct AtomicQueue<Value> {
    private let queue: DispatchQueue
    private var item: Value

    public init(_ wrappedValue: Value) {
        item = wrappedValue
        queue = .init(label: "com.jonahaung.xui.\(Value.self)")
    }

    public var wrappedValue: Value {
        get {
            queue.sync { item }
        }
        set {
            queue.sync { item = newValue }
        }
    }
}
