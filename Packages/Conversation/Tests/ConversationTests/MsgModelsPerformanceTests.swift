//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import Conversation
import Database
import Foundation
import Testing

struct MsgModelsPerformanceTests {
    @Test
    @MainActor
    func benchmark10kBidirectionalFlow() {
        let clock = ContinuousClock()
        let conversationID = "perf-conversation"
        let startDate = Date(timeIntervalSince1970: 1_700_000_000)
        let base = Self.makeMessages(
            count: 10000,
            conversationID: conversationID,
            startDate: startDate,
            startIndex: 0
        )

        let setStart = clock.now
        let models = MsgModels(base)
        let setElapsed = setStart.duration(to: clock.now)

        let prependBatch = Self.makeMessages(
            count: 200,
            conversationID: conversationID,
            startDate: startDate.addingTimeInterval(-200),
            startIndex: -200
        )
        let prependStart = clock.now
        _ = models.prepend(msgs: prependBatch, preserveAnchor: base[2000].uid)
        let prependElapsed = prependStart.duration(to: clock.now)

        let appendBatch = Self.makeMessages(
            count: 200,
            conversationID: conversationID,
            startDate: startDate.addingTimeInterval(10000),
            startIndex: 10000
        )
        let appendStart = clock.now
        for message in appendBatch {
            models.insert(msg: message)
        }
        let appendElapsed = appendStart.duration(to: clock.now)

        let jumpStart = clock.now
        let jumped = models.jump(to: base[5000].uid)
        let jumpElapsed = jumpStart.duration(to: clock.now)

        #expect(jumped)
        #expect(models.count == 10400)
        #expect(models.renderedModels.count <= 260)

        let setMs = Self.milliseconds(setElapsed)
        let prependMs = Self.milliseconds(prependElapsed)
        let appendMs = Self.milliseconds(appendElapsed)
        let jumpMs = Self.milliseconds(jumpElapsed)

        #expect(setMs < 2500)
        #expect(prependMs < 400)
        #expect(appendMs < 1500)
        #expect(jumpMs < 100)
    }
}

private extension MsgModelsPerformanceTests {
    static func makeMessages(
        count: Int,
        conversationID: String,
        startDate: Date,
        startIndex: Int
    ) -> [Message] {
        var result: [Message] = []
        result.reserveCapacity(count)
        for offset in 0..<count {
            let index = startIndex + offset
            let date = startDate.addingTimeInterval(TimeInterval(offset))
            result.append(
                Message(
                    uid: "msg-\(index)",
                    senderID: index % 2 == 0 ? "u-a" : "u-b",
                    conID: conversationID,
                    text: "message-\(index)",
                    date: date,
                    incomingStatus: .none,
                    outgoingStatus: [:],
                    attachments: [],
                    reactions: []
                )
            )
        }
        return result
    }

    static func milliseconds(_ duration: Duration) -> Double {
        Double(duration.components.seconds) * 1000
            + Double(duration.components.attoseconds) / 1_000_000_000_000_000
    }
}
