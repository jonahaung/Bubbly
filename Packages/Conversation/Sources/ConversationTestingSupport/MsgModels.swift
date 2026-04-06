import Foundation

@MainActor
public final class MsgModels {
    private enum Constants {
        static let maxRenderedCount = 260
    }

    private var storage: [Message]
    private var renderedRange: Range<Int>

    public init(_ msgs: [Message] = []) {
        storage = msgs.sorted(by: Self.precedes)
        renderedRange = 0..<0
        recenterWindow(around: storage.indices.last)
    }

    public var count: Int {
        storage.count
    }

    public var renderedModels: [RenderedMessage] {
        storage[renderedRange].map(RenderedMessage.init)
    }

    @discardableResult
    public func prepend(msgs: [Message], preserveAnchor anchorID: String?) -> Bool {
        guard !msgs.isEmpty else {
            return anchorID.flatMap(index(of:)) != nil
        }

        storage.insert(contentsOf: msgs, at: 0)
        storage.sort(by: Self.precedes)
        recenterWindow(around: anchorID.flatMap(index(of:)))
        return anchorID.flatMap(index(of:)) != nil
    }

    public func insert(msg: Message) {
        let index = insertionIndex(for: msg)
        storage.insert(msg, at: index)
        if renderedRange.isEmpty {
            recenterWindow(around: index)
            return
        }
        if index <= renderedRange.lowerBound {
            recenterWindow(around: renderedRange.lowerBound + 1)
        } else if index < renderedRange.upperBound {
            recenterWindow(around: index)
        } else {
            recenterWindow(around: renderedRange.lowerBound)
        }
    }

    @discardableResult
    public func jump(to id: String) -> Bool {
        guard let index = index(of: id) else {
            return false
        }
        recenterWindow(around: index)
        return true
    }

    private func index(of id: String) -> Int? {
        storage.firstIndex { $0.uid == id }
    }

    private func insertionIndex(for msg: Message) -> Int {
        var lowerBound = 0
        var upperBound = storage.count

        while lowerBound < upperBound {
            let midpoint = (lowerBound + upperBound) / 2
            if Self.precedes(storage[midpoint], msg) {
                lowerBound = midpoint + 1
            } else {
                upperBound = midpoint
            }
        }

        return lowerBound
    }

    private func recenterWindow(around index: Int?) {
        guard !storage.isEmpty else {
            renderedRange = 0..<0
            return
        }

        let count = min(Constants.maxRenderedCount, storage.count)
        guard count < storage.count else {
            renderedRange = 0..<storage.count
            return
        }

        let center = min(max(index ?? (storage.count - 1), 0), storage.count - 1)
        var lowerBound = max(0, center - (count / 2))
        var upperBound = lowerBound + count

        if upperBound > storage.count {
            upperBound = storage.count
            lowerBound = upperBound - count
        }

        renderedRange = lowerBound..<upperBound
    }

    private static func precedes(_ lhs: Message, _ rhs: Message) -> Bool {
        if lhs.date != rhs.date {
            return lhs.date < rhs.date
        }
        return lhs.uid < rhs.uid
    }
}

public struct RenderedMessage: Identifiable, Hashable, Sendable {
    public let msg: Message

    public init(_ msg: Message) {
        self.msg = msg
    }

    public var id: String {
        msg.uid
    }
}
