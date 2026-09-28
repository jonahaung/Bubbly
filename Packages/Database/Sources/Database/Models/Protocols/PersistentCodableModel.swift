//  PersistentCodableModel.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import XUI
import Shared
import SwiftData
import Foundation

public protocol PersistentCodableModel: PersistentModel, UIdentifiable, Codable {
    associatedtype SendableType: Sendable & Hashable & UIdentifiable & Encodable

    init(from sendable: SendableType)
    func toSendable() -> SendableType
    func update(from item: Self.SendableType) throws -> Self
}

public extension PersistentCodableModel {
    func update(from item: Self.SendableType) throws -> Self {
        try copyMatchingProperties(from: item)
    }
}
