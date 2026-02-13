import Foundation
import XUI

public protocol ContactRepresentable: UIdentifiable, StringMergable {
	var uid: String { get }
	var name: String { get set }
	var mobile: String { get }
	var photoURL: String { get set }
	var pushToken: String { get set }
	var publicKeyString: String { get set }
}

public extension ContactRepresentable {
	func merging(from source: some ContactRepresentable) -> Self {
		guard source.uid == uid else { return self }
		var copy = self
		copy.name = mergedString(copy.name, from: source.name)
		copy.photoURL = mergedString(copy.photoURL, from: source.photoURL)
		copy.pushToken = mergedString(copy.pushToken, from: source.pushToken)
		copy.publicKeyString = mergedString(copy.publicKeyString, from: source.publicKeyString)
		return copy
	}
}
