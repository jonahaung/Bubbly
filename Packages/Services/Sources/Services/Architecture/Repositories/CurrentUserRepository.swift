// © 2026 Aung Ko Min

import Core
import Database
import FirebaseAuth
import FirebaseMessaging
import Foundation
import XUI

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

    @concurrent public func updateIfNeeded() async throws {
        guard let firUser = Auth.auth().currentUser else {
            throw XError.notLoggedIn
        }

        let storage = GroupStorage.shared

        var newModel = CurrentUserModel(firUser)
        let publicKeyString = CryptoService.shared.base64PublicKeyString(for: firUser.uid)
        newModel.publicKeyString = publicKeyString
        storage.save(firUser.uid, for: .auth(.currentUserID))
        storage.save(publicKeyString, for: .security(.publicKey(id: firUser.uid)))

        if let remoteModel: CurrentUserModel = try await ContactHttpClient.shared.contact(uid: firUser.uid) {
            if newModel != remoteModel {
                try await ContactHttpClient.shared.updateContact(newModel)
                await ToastPresenter.show("Profile Updated")
            }
        } else {
            try await ContactHttpClient.shared.updateContact(newModel)
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
                    do {
                        try await self.updateIfNeeded()
                    } catch {
                        // Reload notifications are best-effort; a later notification can retry.
                    }
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
