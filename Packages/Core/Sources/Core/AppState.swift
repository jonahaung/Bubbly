//  AppState.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Foundation

// MARK: - AppLifecycleState

public enum AppLifecycleState: String {
    case active
    case inactive
    case background
    case unknown
}

// MARK: - AppStateStore

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
            let state = AppLifecycleState(rawValue: raw) else
        {
            return .unknown
        }

        return state
    }
}
