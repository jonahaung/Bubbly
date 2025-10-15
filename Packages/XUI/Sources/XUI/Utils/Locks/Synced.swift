//
//  Synced.swift
//  XUI
//
//  Created by Aung Ko Min on 7/11/24.
//

import Foundation

public func Synced<T>(_ lock: Any, closure: () -> T) -> T {
    objc_sync_enter(lock)
    let r = closure()
    objc_sync_exit(lock)
    return r
}
