//
//  CancelBag.swift
//  CountriesSwiftUI
//
//  Created by Alexey Naumov on 04.04.2020.
//  Copyright © 2020 Alexey Naumov. All rights reserved.
//

import Combine

public final class CancelBag: @unchecked Sendable {

    fileprivate(set) var  subscriptions = Set<AnyCancellable>()
    public init( subscriptions: Set<AnyCancellable> = Set<AnyCancellable>()) {
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
