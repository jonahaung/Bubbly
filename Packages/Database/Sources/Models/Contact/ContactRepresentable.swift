//
//  ContactRepresentable.swift
//  Database
//
//  Created by Aung Ko Min on 29/10/25.
//

import Foundation

public protocol ContactRepresentable: Codable, Sendable, Hashable, UIdentifiable {
	var uid: String { get }
	var name: String { get set }
	var mobile: String { get }
	var photoURL: String { get set }
	var pushToken: String { get set }
	var publicKeyString: String { get set }
}

public extension ContactRepresentable {
	func merging(from source: any ContactRepresentable) -> Self {
		guard source.uid == uid else { return self }
		var copy = self
		func merged(_ current: String, _ incoming: String) -> String {
			let trimmed = incoming.trimmingCharacters(in: .whitespacesAndNewlines)
			return trimmed.isEmpty ? current : trimmed
		}
		copy.name = merged(copy.name, source.name)
		copy.photoURL = merged(copy.photoURL, source.photoURL)
		copy.pushToken = merged(copy.pushToken, source.pushToken)
		copy.publicKeyString = merged(copy.publicKeyString, source.publicKeyString)
		return copy
	}
}
