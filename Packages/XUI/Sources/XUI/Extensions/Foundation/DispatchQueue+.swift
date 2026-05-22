//  DispatchQueue+.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import Foundation

extension DispatchQueue {
    public static func delay(
        _ time: TimeInterval = 0.2,
        _ completion: @escaping @MainActor @Sendable () -> Void
    ) {
        Task.detached(priority: .background) {
            try? await Task.sleep(nanoseconds: UInt64(time * 1_000_000_000))
            await MainActor.run {
                completion()
            }
        }
    }
}
