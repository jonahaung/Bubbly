//
//  RecursiveLock.swift
//  
//
//  Created by Aung Ko Min on 23/2/24.
//

import Foundation
public final class RecursiveLock {
    private let lock = NSRecursiveLock()
    public func sync<T>(action: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return action()
    }
    public init() {
    }
}
