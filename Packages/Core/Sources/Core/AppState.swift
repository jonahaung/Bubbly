//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public enum AppLifecycleState: String {
    case active
    case inactive
    case background
    case unknown
}

public enum AppStateStore {
    public static let key = "app_state"

    @inlinable
    public static func set(_ state: AppLifecycleState) {
        UserDefaults(suiteName: AppInformation.groupID)?
            .set(state.rawValue, forKey: key)
    }

    @inlinable
    public static func read() -> AppLifecycleState {
        guard let raw = UserDefaults(suiteName: AppInformation.groupID)?
            .string(forKey: key),
            let state = AppLifecycleState(rawValue: raw)
        else {
            return .unknown
        }
        return state
    }
}
