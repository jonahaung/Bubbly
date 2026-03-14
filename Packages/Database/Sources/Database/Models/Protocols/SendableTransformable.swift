//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftData

public protocol SendableTransformable: PersistentModel, UIdentifiable {

	associatedtype SendableType: Sendable & Hashable & UIdentifiable

    init(from sendable: SendableType)
    func toSendable() -> SendableType
    func update(from item: Self.SendableType)
}
