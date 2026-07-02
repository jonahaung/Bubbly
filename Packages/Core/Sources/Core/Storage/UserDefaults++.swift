//  UserDefaults++.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Foundation

public extension UserDefaults {
    nonisolated(unsafe) static let group = UserDefaults(suiteName: AppInformation.groupID) ?? .standard
}
