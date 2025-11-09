//
//  ContactRepresentable.swift
//  Database
//
//  Created by Aung Ko Min on 29/10/25.
//

import Foundation

public protocol ContactRepresentable: Codable, Sendable, Hashable, UIdentifiable, StringMergable {
	var uid: String { get }
	var name: String { get set }
	var mobile: String { get }
	var photoURL: String { get set }
	var pushToken: String { get set }
	var publicKeyString: String { get set }
}

extension ContactRepresentable {
	public func merging(from source: any ContactRepresentable) -> Self {
		guard source.uid == uid else { return self }
		var copy = self
		copy.name = mergedString(current: copy.name, incoming: source.name)
		copy.photoURL = mergedString(current: copy.photoURL, incoming: source.photoURL)
		copy.pushToken = mergedString(current: copy.pushToken, incoming: source.pushToken)
		copy.publicKeyString = mergedString(current: copy.publicKeyString, incoming: source.publicKeyString)
		return copy
	}
}
