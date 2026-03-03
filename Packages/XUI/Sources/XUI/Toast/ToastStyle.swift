//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI

public enum ToastStyle: Sendable, Hashable, CaseIterable {
    case `default`, top, bottom

    var alignment: Alignment {
        switch self {
        case .default:
            .top
        case .top:
            .top
        case .bottom:
            .bottom
        }
    }

    var edge: Edge {
        if alignment == .top {
            return .top
        }
        return .bottom
    }
}
