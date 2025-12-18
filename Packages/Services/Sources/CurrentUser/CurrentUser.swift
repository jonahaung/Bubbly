//
//  CurrentUser.swift
//
//  Created by Aung Ko Min on 2/7/24.
//

import Core
import Database
import FirebaseAuth
import FirebaseMessaging
import Foundation
import XUI

@MainActor
@Observable
public final class CurrentUser {
    public enum XError: Error {
        case notLoggedIn
        case noDeviceToken
    }

    public var model: CurrentUserModel
    private let cancelBag = CancelBag()

	public init(_ model: CurrentUserModel) {
		self.model = model
		observeReloadNotification()
    }

    @concurrent private func updateIfNeeded() async throws {
        guard let firUser = Auth.auth().currentUser else {
            throw XError.notLoggedIn
        }
        let storage = GroupStorage.shared

        let newModel = CurrentUserModel(firUser)
        storage.save(newModel.pushToken, for: .device(.deviceToken))

        let remoteModel: CurrentUserModel? = try? await FirestoreRepo.getModel(
            for: newModel.uid,
            collection: .users,
            field: .uid
        )
        if newModel != remoteModel {
            try await FirestoreRepo
                .update(
                    value: newModel.dictionary,
                    collectionPath: .users,
                    to: newModel.uid
                )
            await ToastPresenter.show("Profile Updated")
        }
        await updateModelOnMain(newModel)
    }

    @MainActor private func updateModelOnMain(_ newValue: CurrentUserModel) {
        model = newValue
    }
//
//    public func start() {
//        debugPrint("4️⃣ CurrentUser starting...")
//        observeReloadNotification()
//        CurrentUser.reload()
//    }
//
    private func observeReloadNotification() {
        NotificationCenter.default
            .publisher(for: .reloadCurrentUser)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                Task {
                    try await self.updateIfNeeded()
                }
            }
            .store(in: cancelBag)
    }

    deinit {
        MainActor.assumeIsolated {
            cancelBag.cancel()
        }
    }
}

public extension CurrentUser {
    static func reload() {
        NotificationCenter.default.post(name: .reloadCurrentUser, object: nil)
    }
}

private extension Notification.Name {
    static let reloadCurrentUser = Notification.Name(AppInformation.appID + ".reloadCurrentUser")
}
