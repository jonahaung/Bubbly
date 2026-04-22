//  Task+Delay.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import SwiftUI

public extension Task where Success == Never, Failure == Never {
    static func delay(_ seconds: TimeInterval) async {
        let nanos = UInt64(max(0, seconds) * 1_000_000_000)
        try? await Task.sleep(nanoseconds: nanos)
    }
}
