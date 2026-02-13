import Foundation

public struct UserDefaultsKey<T: Codable> {
	public var name: String
	public var `default`: T
}

public extension UserDefaults {
	func get<T>(_ key: UserDefaultsKey<T>) -> T {
		guard
			let data = data(forKey: key.name),
			let box = try? JSONDecoder().decode(Box<T>.self, from: data)
		else { return key.default }

		return box.value
	}

	func set<T>(_ key: UserDefaultsKey<T>, _ value: T?) {
		if let value {
			let box = Box(value: value)
			if let data = try? JSONEncoder().encode(box) {
				set(data, forKey: key.name)
			} else {
				removeObject(forKey: key.name)
			}
		} else {
			removeObject(forKey: key.name)
		}
	}
}

private struct Box<T: Codable>: Codable {
	var value: T
}
