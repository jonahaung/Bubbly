//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

public extension Text {
    init(markdown text: String) {
        do {
            let attributedString = try AttributedString(markdown: text)
            self = .init(attributedString)
        } catch {
            self = .init(text)
        }
    }
}
