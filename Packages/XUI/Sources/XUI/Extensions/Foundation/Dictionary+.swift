//
//  File.swift
//  
//
//  Created by Aung Ko Min on 10/6/23.
//

import Foundation

public extension Dictionary {
    var tuples: [(Key, Value)] {
        map({ ($0.key, $0.value) })
    }
}
