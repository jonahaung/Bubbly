//
//  LazyConstant.swift
//  XUI
//
//  Created by Aung Ko Min on 23/6/25.
//

import Foundation

@propertyWrapper
public struct LazyConstant<Value> {

    private(set) var storage: Value?
    let constructor: () -> Value

    /// Creates a constnat lazy property with the closure to be executed to provide an initial value once the wrapped property is first accessed.
    ///
    /// This constructor is automatically used when assigning the initial value of the property, so simply use:
    ///
    ///     @Lazy var text = "Hello, World!"
    ///
    public init(wrappedValue constructor: @autoclosure @escaping () -> Value) {
        self.constructor = constructor
    }

    public var wrappedValue: Value {
        mutating get {
            if storage == nil {
                storage = constructor()
            }
            return storage!
        }
    }

    /// Resets the wrapper to its initial state. The wrapped property will be initialized on next read access.
    public mutating func reset() {
        storage = nil
    }
}
