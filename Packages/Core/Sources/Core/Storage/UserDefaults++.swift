//
//  UserDefaults++.swift
//  Core
//
//  Created by Aung Ko Min on 13/4/26.
//

import Foundation

public extension UserDefaults {
    nonisolated(unsafe) static let group = UserDefaults(suiteName: AppInformation.groupID) ?? .standard
}
