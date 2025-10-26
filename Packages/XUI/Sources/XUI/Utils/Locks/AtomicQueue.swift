//
//  AtomicQueue.swift
//  XUI
//
//  Created by Aung Ko Min on 27/10/24.
//

import Foundation

@propertyWrapper
public struct AtomicQueue<Value> {

    private let queue = DispatchQueue(label: "com.jonahaung.AtomicQueue")
    private var value: Value

    public init(wrappedValue: Value) {
        self.value = wrappedValue
    }

    public var wrappedValue: Value {
        get {
            return queue.sync { value }
        }
        set {
            queue.sync { value = newValue }
        }
    }
}
