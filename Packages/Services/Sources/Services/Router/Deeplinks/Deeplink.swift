//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public enum Deeplink: Hashable, Sendable {
    case home
    case profile(id: String)
    case conversation(id: String)
    case settings
}
