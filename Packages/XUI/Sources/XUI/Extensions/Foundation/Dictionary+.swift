//  Dictionary+.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import Foundation

public extension Dictionary {
    var tuples: [(Key, Value)] {
        map { ($0.key, $0.value) }
    }
}
