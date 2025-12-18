//
//  CurrentUserID.swift
//  Core
//
//  Created by Aung Ko Min on 8/11/25.
//

import FirebaseAuth

public var currentUserId: String? {
	Auth.auth().currentUser?.uid ?? GroupStorage.shared.string(for: .auth(.currentUserID))
}
