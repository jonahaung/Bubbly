//
//  FirePhoneLoginViewState.swift
//  FirebasePhoneLogin
//
//  Created by Aung Ko Min on 21/4/24.
//

import FirebaseAuth
import Foundation

enum FirePhoneLoginViewState: Hashable, Identifiable {
	var id: FirePhoneLoginViewState {
		self
	}

	case enterPhoneNumber, verifyOTP
	case loggedIn(user: User, isNewUser: Bool)
	case error(String)

	var title: String {
		switch self {
		case .enterPhoneNumber:
			"Mobile Number"
		case .verifyOTP:
			"OTP"
		case .error:
			"Error"
		case .loggedIn:
			"Success"
		}
	}

	var subtitle: String {
		switch self {
		case .enterPhoneNumber:
			"Please enter the mobile number"
		case .verifyOTP:
			"Please enter the one-time-password that sent via sms"
		case let .error(error):
			error
		case let .loggedIn(user, _):
			user.displayName ?? user.phoneNumber ?? user.uid
		}
	}
}
