//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

struct UnlocalizedError: LocalizedError {
    let errorDescription: String?

    init(error: Error) {
        errorDescription = error.localizedDescription
    }
}
