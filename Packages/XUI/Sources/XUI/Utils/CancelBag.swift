//  CancelBag.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import Combine

public final class CancelBag: @unchecked Sendable {
    fileprivate(set) var subscriptions: Set<AnyCancellable> = []
    public init(subscriptions: Set<AnyCancellable> = Set<AnyCancellable>()) {
        self.subscriptions = subscriptions
    }

    public func cancel() {
        subscriptions.removeAll()
    }
}

public extension AnyCancellable {
    func store(in cancelBag: CancelBag) {
        cancelBag.subscriptions.insert(self)
    }
}
