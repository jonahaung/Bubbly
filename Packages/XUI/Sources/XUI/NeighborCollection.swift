//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public struct NeighborCollection<Base: BidirectionalCollection>: BidirectionalCollection {
    public typealias Element = (
        previous: Base.Element?,
        current: Base.Element,
        next: Base.Element?
    )

    public typealias Index = Base.Index

    private let base: Base

    public init(_ base: Base) {
        self.base = base
    }

    // MARK: - Collection

    public var startIndex: Index {
        base.startIndex
    }

    public var endIndex: Index {
        base.endIndex
    }

    public func index(after i: Index) -> Index {
        base.index(after: i)
    }

    public subscript(position: Index) -> Element {
        let current = base[position]

        let previous: Base.Element? =
            position > base.startIndex
                ? base[base.index(before: position)]
                : nil

        let nextIndex = base.index(after: position)
        let next: Base.Element? =
            nextIndex < base.endIndex
                ? base[nextIndex]
                : nil

        return (previous, current, next)
    }

    // MARK: - BidirectionalCollection

    public func index(before i: Index) -> Index {
        base.index(before: i)
    }
}

extension NeighborCollection: RandomAccessCollection where Base: RandomAccessCollection {}

public extension Collection where Self: BidirectionalCollection {
    var neighbors: NeighborCollection<Self> {
        NeighborCollection(self)
    }
}
