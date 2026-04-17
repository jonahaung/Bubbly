//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import Foundation

public struct SeededRandomGenerator: RandomNumberGenerator {
    private var state: UInt64

    public init(seed: Int) {
        // Mix the Int seed into a 64-bit state; avoid zero state
        var x = UInt64(bitPattern: Int64(seed))
        if x == 0 {
            x = 0x9E37_79B9_7F4A_7C15
        } // non-zero default
        // Scramble a bit on init
        state = SeededRandomGenerator.splitmix64(&x)
    }

    public mutating func next() -> UInt64 {
        SeededRandomGenerator.splitmix64(&state)
    }

    private static func splitmix64(_ x: inout UInt64) -> UInt64 {
        x &+= 0x9E37_79B9_7F4A_7C15
        var z = x
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
