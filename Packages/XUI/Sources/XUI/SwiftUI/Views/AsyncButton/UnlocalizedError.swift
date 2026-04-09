//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import Foundation

struct UnlocalizedError: LocalizedError {
    let errorDescription: String?

    init(error: Error) {
        errorDescription = error.localizedDescription
    }
}
