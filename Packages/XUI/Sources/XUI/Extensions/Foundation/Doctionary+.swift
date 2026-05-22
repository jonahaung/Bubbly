//  Doctionary+.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import Foundation

//public extension Dictionary {
//    mutating func merge<K: Hashable>(
//        from source: some Sequence<(K, Value)>,
//        keyMapping: (K) -> Key?
//    ) {
//        for (sourceKey, sourceValue) in source {
//            guard let targetKey = keyMapping(sourceKey) else { continue }
//            self[targetKey] = sourceValue
//        }
//    }
//
//    mutating func merge(from source: [Key: Value]) {
//        merge(source) { _, new in new }
//    }
//}
//
//public extension Encodable where Self: Decodable {
//    func merging(from source: some Codable) throws -> Self {
//        var dic = try asDictionary()
//        let sourceDic = try source.asDictionary()
//        dic.merge(from: sourceDic)
//        let data = try JSONSerialization.data(withJSONObject: dic, options: [])
//        return try JSONDecoder().decode(Self.self, from: data)
//    }
//}
