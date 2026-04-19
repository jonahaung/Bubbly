//
//  MessageDiff.swift
//  Conversation
//
//  Created by Aung Ko Min on 18/4/26.
//

import Database
import Foundation
import XUI

public struct Diff<T: Hashable & Identifiable> where T.ID == String {

    public struct Change {
        public enum Kind {
            case insert(Int)
            case remove(Int)
            case update(Int)
        }

        public let kind: Kind
        public let message: T
    }

    public static func diff(
        old: [T],
        new: [T]
    ) -> [Change] {

        var changes: [Change] = []

        let oldMap = Dictionary(
            uniqueKeysWithValues: old.enumerated().map {
                ($0.element.id, $0.offset)
            }
        )
        let newMap = Dictionary(
            uniqueKeysWithValues: new.enumerated().map {
                ($0.element.id, $0.offset)
            }
        )
        for (id, oldIndex) in oldMap where newMap[id] == nil {
            changes.append(
                .init(kind: .remove(oldIndex), message: old[oldIndex])
            )
        }
        for (id, newIndex) in newMap {
            if let oldIndex = oldMap[id] {
                if old[oldIndex] != new[newIndex] {
                    changes.append(
                        .init(kind: .update(newIndex), message: new[newIndex])
                    )
                }
            } else {
                changes.append(
                    .init(kind: .insert(newIndex), message: new[newIndex])
                )
            }
        }
        return changes.sorted {
            switch ($0.kind, $1.kind) {
            case (.remove(let a), .remove(let b)): return a > b
            default: return true
            }
        }
    }
}
