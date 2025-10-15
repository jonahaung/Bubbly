//
//  Settings.swift
//  Core
//
//  Created by Aung Ko Min on 15/8/25.
//

import Foundation

public enum Settings {

	public enum Layout {
		public static var chatMsgSpacing: Int {
			get {
				let value = GroupAppStorage.shared
					.integer(
						for: .layout(.chatMsgSpacing)
					)
				return value == 0 ? 1 : value
			}
			set {
				GroupAppStorage.shared.save(value: newValue, for: .layout(.chatMsgSpacing))
			}
		}

		public static var minutesForChatMsgGrouping: Int {
			get {
				let value = GroupAppStorage.shared
					.integer(
						for: .limit(.minutesForChatMsgGrouping)
					)
				return value == 0 ? 15 : value
			}
			set {
				GroupAppStorage.shared.save(value: newValue, for: .limit(.minutesForChatMsgGrouping))
			}
		}
	}

	public enum Pagination {
		public static var pageSize: Int {
			get {
				let value = GroupAppStorage.shared
					.integer(
						for: .limit(.paginationPageSize)
					)
				return value == 0 ? 30 : value
			}
			set {
				GroupAppStorage.shared
					.save(value: newValue, for: .limit(.paginationPageSize))
			}
		}
	}
}
