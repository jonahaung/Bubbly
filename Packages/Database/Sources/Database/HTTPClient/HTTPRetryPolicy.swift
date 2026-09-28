//  HTTPRetryPolicy.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Foundation

public struct HTTPRetryPolicy: Sendable, Equatable {
    public let maximumRetryCount: Int
    public let initialDelay: Duration
    public let maximumDelay: Duration

    public init(
        maximumRetryCount: Int = 2,
        initialDelay: Duration = .milliseconds(250),
        maximumDelay: Duration = .seconds(2)
    ) {
        let initialDelay = max(.zero, initialDelay)
        self.maximumRetryCount = max(0, maximumRetryCount)
        self.initialDelay = initialDelay
        self.maximumDelay = max(initialDelay, maximumDelay, .zero)
    }

    public static let `default`: HTTPRetryPolicy = .init()
    public static let disabled: HTTPRetryPolicy = .init(maximumRetryCount: 0)

    func delay(forRetry retry: Int) -> Duration {
        min(initialDelay * (1 << min(retry, 20)), maximumDelay)
    }
}
