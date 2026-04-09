//
// Copyright © 2026 Aung Ko Min. All rights reserved.
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
