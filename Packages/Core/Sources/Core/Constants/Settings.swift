//  Settings.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import Foundation

public enum Settings {
    public enum Layout {
        public static var chatMsgSpacing: Int {
            get {
                if let value = GroupStorage.shared
                    .integer(
                        for: .layout(.chatMsgSpacing)
                    )
                {
                    return value == 0 ? 1 : value
                }
                return 1
            }
            set {
                GroupStorage.shared.save(newValue, for: .layout(.chatMsgSpacing))
            }
        }

        public static var minutesForChatMsgGrouping: Int {
            get {
                if let value = GroupStorage.shared
                    .integer(
                        for: .limit(.minutesForChatMsgGrouping)
                    )
                {
                    return value == 0 ? 15 : value
                }
                return 15
            }
            set {
                GroupStorage.shared.save(newValue, for: .limit(.minutesForChatMsgGrouping))
            }
        }
    }

    public enum Pagination {
        public static var pageSize: Int {
            get {
                if let value = GroupStorage.shared
                    .integer(
                        for: .limit(.paginationPageSize)
                    )
                {
                    return value == 0 ? 30 : value
                }
                return 30
            }
            set {
                GroupStorage.shared
                    .save(newValue, for: .limit(.paginationPageSize))
            }
        }
    }
}
