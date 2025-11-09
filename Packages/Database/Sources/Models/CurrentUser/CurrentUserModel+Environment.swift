//
//  CurrentUserModel+Environment.swift
//  Services
//
//  Created by Aung Ko Min on 29/10/25.
//

import SwiftUI

private struct CurrentUserEnvironmentKey: EnvironmentKey {
    typealias Value = CurrentUserModel

    static let defaultValue: Value = CurrentUserModel.empty
}

public extension EnvironmentValues {
    var currentUser: CurrentUserModel {
        get { self[CurrentUserEnvironmentKey.self] }
        set { self[CurrentUserEnvironmentKey.self] = newValue }
    }
}
