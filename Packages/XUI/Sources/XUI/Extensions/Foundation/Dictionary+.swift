//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public extension Dictionary {
    var tuples: [(Key, Value)] {
        map { ($0.key, $0.value) }
    }
}
