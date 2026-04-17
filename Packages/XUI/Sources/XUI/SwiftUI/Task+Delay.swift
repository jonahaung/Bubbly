//
//  Task+Delay.swift
//  XUI
//
//  Created by Aung Ko Min on 11/4/26.
//

import SwiftUI

public extension Task where Success == Never, Failure == Never {
    static func delay(_ seconds: TimeInterval) async {
        let nanos = UInt64(max(0, seconds) * 1_000_000_000)
        try? await Task.sleep(nanoseconds: nanos)
    }
}
