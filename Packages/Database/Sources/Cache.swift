//
//  Cache.swift
//  Database
//
//  Created by Aung Ko Min on 2/11/25.
//

import Foundation
import XUI
import Core

@MainActor
public struct Cache {
	public static let shared = Cache()
	public let date = ExpiringCache<String>()
	private init() {}
}
