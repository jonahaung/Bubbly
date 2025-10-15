//
//  FirePhoneLoginProgressState.swift
//  FirebasePhoneLogin
//
//  Created by Aung Ko Min on 21/4/24.
//

import Foundation
import FirebaseAuth

enum FirePhoneLoginProgressState: Hashable {
    case none, loading
    case loggedIn(User, isNewUser: Bool)
}
