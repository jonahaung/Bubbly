//  Duration+TimeInterval.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Foundation

@available(iOS 16.0, *)
@available(macOS 13.0, *)
@available(tvOS 16.0, *)
extension Duration {
    var timeInterval: TimeInterval {
        TimeInterval(components.seconds) + TimeInterval(components.attoseconds) / 1e18
    }
}
