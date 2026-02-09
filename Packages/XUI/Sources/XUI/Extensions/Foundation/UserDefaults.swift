//
//  UserDefaults.swift
//  XUI
//
//  Created by Aung Ko Min on 18/8/25.
//

import Foundation

public extension UserDefaults {
	func setCodable(_ value: some Codable, forKey key: String) {
		if let data = try? JSONEncoder().encode(value) {
			set(data, forKey: key)
		}
	}

	func codable<T: Codable>(forKey key: String) -> T? {
		guard let data = data(forKey: key),
		      let value = try? JSONDecoder().decode(T.self, from: data)
		else {
			return nil
		}
		return value
	}
}
