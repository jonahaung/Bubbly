// © 2026 Aung Ko Min

import Core
import Database
import FirebaseAuth
import FirebaseMessaging
import Foundation
import XUI

// MARK: - CurrentUserRepository

public actor CurrentUserRepository {
    public enum XError: Error {
        case notLoggedIn
        case noDeviceToken
    }

    public var model: CurrentUserModel
    private let cancelBag: CancelBag = .init()

    public init(_ model: CurrentUserModel) {
        self.model = model
        Task { [weak self] in
            guard let self else {
                return
            }

            await observeReloadNotification()
        }
    }

    @concurrent private func updateIfNeeded() async throws {
        guard let firUser = Auth.auth().currentUser else {
            throw XError.notLoggedIn
        }

        let storage = GroupStorage.shared

        let newModel = CurrentUserModel(firUser)
        storage.save(newModel.pushToken, for: .device(.deviceToken))

        if let remoteModel: CurrentUserModel? = try? await FirestoreRepo.getModel(
            for: newModel.uid,
            collection: .users,
            field: .uid,
        ) {
            if newModel != remoteModel {
                try await FirestoreRepo
                    .update(
                        value: newModel.dictionary,
                        collectionPath: .users,
                        to: newModel.uid,
                    )
                await ToastPresenter.show("Profile Updated", allowsBackgroundTap: false)
            }
        } else {
            try await FirestoreRepo.add(newModel, collectionPath: .users, documentID: newModel.uid)
        }
        await update(newModel)
    }

    @concurrent public func reload() async throws {
        try await updateIfNeeded()
    }

    public func update(_ newValue: Database.CurrentUserModel) {
        model = newValue
    }

    private func observeReloadNotification() {
        NotificationCenter.default
            .publisher(for: .reloadCurrentUser)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else {
                    return
                }

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

public extension CurrentUserRepository {
    func reload() {
        NotificationCenter.default.post(name: .reloadCurrentUser, object: nil)
    }
}

private extension Notification.Name {
    static let reloadCurrentUser = Notification.Name(AppInformation.appID + ".reloadCurrentUser")
}
