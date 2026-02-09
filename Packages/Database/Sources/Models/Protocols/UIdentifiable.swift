//
//  UIdentifiable.swift
//  Models
//
//  Created by Aung Ko Min on 14/7/25.
//

import Foundation

public protocol UIdentifiable: Identifiable {
	associatedtype UID = String
	var uid: UID { get }
}

public extension UIdentifiable {
	var id: UID {
		uid
	}
}
