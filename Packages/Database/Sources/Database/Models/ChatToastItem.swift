//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import XUI

public enum ChatToastItem: Conformable {
    case scrollDownButton
    case message(_ msg: Message)
    case none
    public var isEmpty: Bool {
        self == .none
    }

    public var isNotEmpty: Bool {
        !isEmpty
    }
}
