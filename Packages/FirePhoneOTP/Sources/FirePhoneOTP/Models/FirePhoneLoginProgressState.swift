//
//  FirePhoneLoginProgressState.swift
//  FirebasePhoneLogin
//
//  Created by Aung Ko Min on 21/4/24.
//

import FirebaseAuth
import Foundation

enum FirePhoneLoginProgressState: Hashable {
    case none, loading
    case loggedIn(User, isNewUser: Bool)
}
