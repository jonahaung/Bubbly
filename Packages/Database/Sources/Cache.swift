//
//  Cache.swift
//  Database
//
//  Created by Aung Ko Min on 2/11/25.
//

import Core
import Foundation
import XUI

@MainActor
public struct Cache {
    public static let shared = Cache()
    public let date = ExpiringCache<String>()
    private init() {}
}
