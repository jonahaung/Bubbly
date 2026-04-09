//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import Foundation

public struct SeededRandomGenerator: RandomNumberGenerator {
    private var state: UInt64

    public init(seed: Int) {
        // Mix the Int seed into a 64-bit state; avoid zero state
        var x = UInt64(bitPattern: Int64(seed))
        if x == 0 { x = 0x9e3779b97f4a7c15 } // non-zero default
        // Scramble a bit on init
        state = SeededRandomGenerator.splitmix64(&x)
    }

    public mutating func next() -> UInt64 {
        SeededRandomGenerator.splitmix64(&state)
    }

    private static func splitmix64(_ x: inout UInt64) -> UInt64 {
        x &+= 0x9e3779b97f4a7c15
        var z = x
        z = (z ^ (z >> 30)) &* 0xbf58476d1ce4e5b9
        z = (z ^ (z >> 27)) &* 0x94d049bb133111eb
        return z ^ (z >> 31)
    }
}
