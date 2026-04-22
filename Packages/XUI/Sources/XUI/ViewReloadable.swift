//  ViewReloadable.swift
//
//  Copyright © 2025 Aung Ko Min.
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
