//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

@globalActor
public struct SomeActor {
    public actor SomeActor {}
    public static let shared = SomeActor()
}
