//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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
