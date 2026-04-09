//
//  BackgroundTaskHandler.swift
//  Bubbly
//
//  Created by Aung Ko Min on 9/4/26.
//

import Foundation
import BackgroundTasks
import XUI
import Core
import Services

struct BackgroundTaskHandler: Sendable {
	func scheduleAppRefresh() {
		let request = BGAppRefreshTaskRequest(identifier: AppInformation.BackgroundTask.appRefresh)
		request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60 * 60)
		try? BGTaskScheduler.shared.submit(request)
		log("background task registered")
	}

	func handleAppRefresh() async {
		do {
			try await PhoneContactsService.shared.syncContacts()
			await LocalNotificationService.sendAlert(title: "Contact Sync Complete")
		} catch {
			log(error)
		}
	}
}
