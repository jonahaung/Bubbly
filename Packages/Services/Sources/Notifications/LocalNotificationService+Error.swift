//
//  LocalNotificationService+Error.swift
//  Services
//
//  Created by Aung Ko Min on 26/8/25.
//

import Foundation

public protocol ErrorPresenter {}

public extension ErrorPresenter {
	@MainActor
	func showError(_ error: Error) async {
		await LocalNotificationService
			.post(config: .init(title: "Error", body: error.localizedDescription))
	}
	@MainActor
	func showMessage(_ title: String, _ msg: String) async {
		await LocalNotificationService
			.post(config: .init(title: title, body: msg))
	}
}
