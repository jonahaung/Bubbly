//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public protocol ViewReloadable: AnyObject {
    var reloadID: Int { get set }
    func layoutIfNeeded()
}

public extension ViewReloadable {
    func layoutIfNeeded() {
        reloadID += 1
    }
}
