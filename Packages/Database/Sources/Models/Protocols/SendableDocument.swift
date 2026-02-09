//
//  SendableDocument.swift
//  Database
//
//  Created by Aung Ko Min on 12/7/25.
//

import Foundation
import SwiftData

public protocol SendableDocument: UIdentifiable {
	associatedtype SendableType: Sendable & UIdentifiable
	init(from sendable: SendableType)
	func toSendable() -> SendableType
	func update(from item: Self.SendableType)
}
