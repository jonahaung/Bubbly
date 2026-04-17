// © 2026 Aung Ko Min

import Foundation

// MARK: - ErrorPresenter

public protocol ErrorPresenter {}

public extension ErrorPresenter {
    @MainActor
    func showError(_ error: Error) async {
        await LocalNotificationService
            .sendAlert(
                title: "Error",
                body: error.localizedDescription,
            )
    }

    @MainActor
    func showMessage(_ title: String, _ msg: String) async {
        await LocalNotificationService.sendAlert(title: title, body: msg)
    }
}
