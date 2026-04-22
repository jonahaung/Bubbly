//  CurrentUserID.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import FirebaseAuth

public enum CurrentUserID {
    public static func get() throws -> String {
        let id = Auth.auth().currentUser?.uid ?? GroupStorage.shared.string(for: .auth(.currentUserID))

        guard let id else {
            throw CurrentUserIDError.noCurrentUserID
        }
        return id
    }

    enum CurrentUserIDError: Swift.Error {
        case noCurrentUserID
    }
}
