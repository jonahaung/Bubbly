//
//  SeededRandomGenerator.swift
//  XUI
//
//  Deterministic RandomNumberGenerator using SplitMix64
//

import Foundation

public struct SeededRandomGenerator: RandomNumberGenerator {
    private var state: UInt64

    public init(seed: Int) {
        // Mix the Int seed into a 64-bit state; avoid zero state
        var x = UInt64(bitPattern: Int64(seed))
        if x == 0 { x = 0x9E3779B97F4A7C15 } // non-zero default
        // Scramble a bit on init
        state = SeededRandomGenerator.splitmix64(&x)
    }

    public mutating func next() -> UInt64 {
        return SeededRandomGenerator.splitmix64(&state)
    }

    private static func splitmix64(_ x: inout UInt64) -> UInt64 {
        x &+= 0x9E3779B97F4A7C15
        var z = x
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
