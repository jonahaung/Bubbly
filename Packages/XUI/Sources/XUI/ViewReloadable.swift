//
//  Layoutable.swift
//  XUI
//
//  Created by Aung Ko Min on 6/11/25.
//

import Foundation

@MainActor
public protocol ViewReloadable: AnyObject, Sendable {
	var reloadID: Int { get set }
	func layoutIfNeeded()
}
public extension ViewReloadable {
	func layoutIfNeeded() {
		reloadID += 1
	}
}
