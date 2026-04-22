//  AsyncButtonOptions.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import Foundation

public struct AsyncButtonOptions: OptionSet, Sendable {
    public let rawValue: Int

    public static let disableButtonOnLoading: AsyncButtonOptions = .init(rawValue: 1 << 0)
    public static let showProgressViewOnLoading: AsyncButtonOptions = .init(rawValue: 1 << 1)
    public static let showAlertOnError: AsyncButtonOptions = .init(rawValue: 1 << 2)
    public static let disallowParallelOperations: AsyncButtonOptions = .init(rawValue: 1 << 3)
    public static let enableNotificationFeedback: AsyncButtonOptions = .init(rawValue: 1 << 4)
    public static let enableTintFeedback: AsyncButtonOptions = .init(rawValue: 1 << 5)

    public static let all: AsyncButtonOptions = [
        .disableButtonOnLoading,
        .showProgressViewOnLoading,
        .showAlertOnError,
        .disallowParallelOperations,
        .enableNotificationFeedback,
        .enableTintFeedback
    ]
    public static let automatic: AsyncButtonOptions = [
        .disableButtonOnLoading,
        .showAlertOnError
    ]

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}
