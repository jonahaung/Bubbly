//  SendableTransformable.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import SwiftData
import Foundation

public protocol SendableTransformable: PersistentModel, UIdentifiable {
    associatedtype SendableType: Sendable & Hashable & UIdentifiable

    init(from sendable: SendableType)
    func toSendable() -> SendableType
    func update(from item: Self.SendableType)
}
