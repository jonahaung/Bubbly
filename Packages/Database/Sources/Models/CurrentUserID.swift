//
//  CurrentUserID.swift
//  Database
//
//  Created by Aung Ko Min on 24/8/25.
//

import Foundation
import FirebaseAuth

public var currentUserId: String? {
	Auth.auth().currentUser?.uid
}
