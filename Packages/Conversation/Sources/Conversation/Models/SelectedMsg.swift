//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public struct SelectedMsg: Equatable, Sendable {
    public let id: String
    public let previous: String?
    public let next: String?

    public init(id: String, previous: String?, next: String?) {
        self.id = id
        self.previous = previous
        self.next = next
    }
}
