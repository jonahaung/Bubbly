//  AppInformation.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import Foundation

public enum AppInformation {
    public static let appID: String = "com.aungkomin.Bubbly"
    public static let urlScheme: String = "bubbly"
    public static let groupID: String = "group.com.aungkomin.Bubbly"
    public static let iCloudID: String = "iCloud.com.aungkomin.Bubbly"
    public static let keychainGroupID = "keychain.com.aungkomin.Bubbly"
    public static let firebaseProjectID = "bubbly-3c6a9"

    public enum BackgroundTask {
        public static let appRefresh = "com.aungkomin.Bubbly.bg.appRefresh"
        public static let processing = "com.aungkomin.Bubbly.bg.processing"
    }
}
