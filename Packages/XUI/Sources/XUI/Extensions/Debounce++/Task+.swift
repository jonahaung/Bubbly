//
//  File.swift
//  
//
//  Created by Aung Ko Min on 10/6/23.
//

import Foundation

public extension Task where Success == Never, Failure == Never {
    static func sleep(seconds: Double) async throws {
        let duration = UInt64(seconds * 1_000_000_000)
        try await Task.sleep(nanoseconds: duration)
    }
}

public var isOnMainThread: Bool {
    return Thread.isMainThread
}
public func isOnMainThreadOrDie() {
    if !isOnMainThread {
        fatalError("This function must be called on the main thread.")
    }
}
