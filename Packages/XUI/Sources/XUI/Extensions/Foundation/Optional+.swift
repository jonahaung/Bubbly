//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import SwiftUI

/// Optional
public extension Optional {
    var forceUnwrapped: Wrapped! {
        if let value = self {
            return value
        }
        fatalError("explanation")
    }
}

public extension Optional where Wrapped: Collection {
    var isNilOrEmpty: Bool {
        self?.isEmpty ?? true
    }
}

public extension String? {
    var str: String {
        self ?? ""
    }

    var bindable: Binding<String> {
        if let unwrapped = self {
            .constant(unwrapped)
        } else {
            .constant("")
        }
    }
}
