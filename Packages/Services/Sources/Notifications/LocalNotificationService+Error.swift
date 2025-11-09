//
//  LocalNotificationService+Error.swift
//  Services
//
//  Created by Aung Ko Min on 26/8/25.
//

import Foundation

public protocol ErrorPresenter {}

extension ErrorPresenter {
	@MainActor
	public func showError(_ error: Error) async {
		await LocalNotificationService
			.sendAlert(
				title: "Error",
				body: error.localizedDescription
			)
	}

	@MainActor
	public func showMessage(_ title: String, _ msg: String) async {
		await LocalNotificationService.sendAlert(title: title, body: msg)
	}
}
