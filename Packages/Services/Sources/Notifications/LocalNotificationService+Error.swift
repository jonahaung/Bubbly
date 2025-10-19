//
//  LocalNotificationService+Error.swift
//  Services
//
//  Created by Aung Ko Min on 26/8/25.
//

import Foundation

public protocol ErrorPresenter {}

public extension ErrorPresenter {
	func showError(_ error: Error) async {
		await LocalNotificationService.sendAlert(title: error.localizedDescription)
	}
	func showMessage(_ title: String, _ msg: String) async {
		await LocalNotificationService.sendAlert(title: title, body: msg)
	}
}
