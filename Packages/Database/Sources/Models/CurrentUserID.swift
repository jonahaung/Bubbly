//
//  CurrentUserID.swift
//  Database
//
//  Created by Aung Ko Min on 24/8/25.
//

import Foundation
import FirebaseAuth
import Core

public var currentUserId: String? {
	GroupAppStorage.shared.string(for: .auth(.currentUserID)) ?? Auth.auth().currentUser?.uid
}
