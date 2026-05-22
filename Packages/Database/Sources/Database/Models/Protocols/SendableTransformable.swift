//  SendableTransformable.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import SwiftData
import Foundation
import XUI

public protocol SendableTransformable: PersistentModel, UIdentifiable, Codable{
    associatedtype SendableType: Sendable & Hashable & UIdentifiable & Encodable

    init(from sendable: SendableType)
    func toSendable() -> SendableType
    func update(from item: Self.SendableType) throws -> Self
}

public extension SendableTransformable {
    func update(from item: Self.SendableType) throws -> Self {
        try self.copyMatchingProperties(from: item)
    }
}
