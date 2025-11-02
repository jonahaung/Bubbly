//
//  Doctionary++.swift
//  XUI
//
//  Created by Aung Ko Min on 2/11/25.
//

import Foundation

public extension Dictionary {
	mutating func merge<S: Sequence, K: Hashable>(
		from source: S,
		keyMapping: (K) -> Key?
	) where S.Element == (K, Value) {
		for (sourceKey, sourceValue) in source {
			guard let targetKey = keyMapping(sourceKey) else { continue }
			self[targetKey] = sourceValue
		}
	}
	mutating func merge(from source: [Key: Value]) {
		self.merge(source) { _, new in new }
	}
}
public extension Encodable where Self: Decodable {
	func merging<T: Codable>(from source: T) throws -> Self {
		var dic = try self.asDictionary()
		let sourceDic = try source.asDictionary()
		dic.merge(from: sourceDic)
		let data = try JSONSerialization.data(withJSONObject: dic, options: [])
		let merged = try JSONDecoder().decode(Self.self, from: data)
		return merged
	}
}
