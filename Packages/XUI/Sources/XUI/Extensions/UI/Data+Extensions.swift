import Foundation

public extension Data {
	init?(path: String) {
		try? self.init(contentsOf: URL(fileURLWithPath: path))
	}

	func write(path: String, options: Data.WritingOptions = []) {
		try? write(to: URL(fileURLWithPath: path), options: options)
	}
}
