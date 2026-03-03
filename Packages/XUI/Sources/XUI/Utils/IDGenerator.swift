//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public actor IDGenerator {
    public static let shared = IDGenerator()

    private static let ascendingChars = Array(
        "-0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz"
    )

    private static let descendingChars = Array(ascendingChars.reversed())

    private var lastTimestamp: UInt64 = 0
    private var lastRandomValues: [Int] = Array(repeating: 0, count: 12)

    private let dateProvider: () -> Date

    public init(dateProvider: @escaping () -> Date = { Date() }) {
        self.dateProvider = dateProvider
    }

    public func make(ascending: Bool = true) -> String {
        let chars = ascending
            ? Self.ascendingChars
            : Self.descendingChars

        precondition(!chars.isEmpty)

        var timestampChars = Array(repeating: chars[0], count: 8)
        var now = UInt64(dateProvider().timeIntervalSince1970 * 1000)

        let isDuplicateTimestamp = now == lastTimestamp
        lastTimestamp = now

        for index in stride(from: 7, through: 0, by: -1) {
            timestampChars[index] = chars[Int(now % 64)]
            now >>= 6
        }

        var id = String(timestampChars)

        if isDuplicateTimestamp {
            incrementRandomValues()
        } else {
            generateRandomValues()
        }

        for value in lastRandomValues {
            id.append(chars[value])
        }

        assert(id.utf8.count == 20)
        return id
    }

    private func generateRandomValues() {
        for index in 0..<lastRandomValues.count {
            lastRandomValues[index] = Int(
                64 * Double(arc4random()) / Double(UInt32.max)
            )
        }
    }

    private func incrementRandomValues() {
        for index in stride(from: lastRandomValues.count - 1, through: 0, by: -1) {
            if lastRandomValues[index] < 63 {
                lastRandomValues[index] += 1
                return
            }
            lastRandomValues[index] = 0
        }
    }
}
