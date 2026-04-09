//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import Foundation

public func Synced<T>(_ lock: Any, closure: () -> T) -> T {
    objc_sync_enter(lock)
    let r = closure()
    objc_sync_exit(lock)
    return r
}
