//
//  FirePhoneLoginViewState.swift
//  FirebasePhoneLogin
//
//  Created by Aung Ko Min on 21/4/24.
//

import Foundation
import FirebaseAuth

enum FirePhoneLoginViewState: Hashable, Identifiable {
    var id: FirePhoneLoginViewState { self }
    case enterPhoneNumber, verifyOTP
    case loggedIn(user: User, isNewUser: Bool)
    case error(String)
    
    var title: String {
        switch self {
        case .enterPhoneNumber:
            return "Mobile Number"
        case .verifyOTP:
            return "OTP"
        case .error:
            return "Error"
        case .loggedIn:
            return "Success"
        }
    }
    var subtitle: String {
        switch self {
        case .enterPhoneNumber:
            return "Please enter the mobile number"
        case .verifyOTP:
            return "Please enter the one-time-password that sent via sms"
        case .error(let error):
            return error
        case .loggedIn(let user, _):
            return user.displayName ?? user.phoneNumber ?? user.uid
        }
    }
}
