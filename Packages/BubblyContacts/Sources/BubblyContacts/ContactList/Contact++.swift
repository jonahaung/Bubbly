//
//  Contact++.swift
//  BubblyContacts
//
//  Created by Aung Ko Min on 10/4/26.
//

import Database

public extension Contact {
	var firstCharacter: String {
		if let first = name.first {
			return String(first).uppercased()
		}
		return ""
	}
}
