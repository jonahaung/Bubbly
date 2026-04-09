// © 2026 Aung Ko Min

import SwiftUI

public struct SelectedMsg: Hashable, Identifiable, Sendable {
    public var id: String
    public var previous: String? = nil
    public var next: String? = nil

    public init(id: String, previous: String? = nil, next: String? = nil) {
        self.id = id
        self.previous = previous
        self.next = next
    }
}
