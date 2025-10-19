//
//  AuthService.swift
//  Services
//
//  Created by Aung Ko Min on 21/5/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseMessaging
import FirebaseFirestore
import XUI
import Database
import Core

@MainActor
@Observable
public class AuthService {

	public enum AuthState: Sendable {
		case loggedIn(user: ContactSnapshot), loggedOut, newUser(user: ContactSnapshot), unknown
	}

	public var authState: AuthState = .unknown
	private let cancelBag = CancelBag()

	public init() {
		observeAuthState()
	}

	public func observeAuthState() {
		authState = determineAuthState()
		NotificationCenter.default
			.publisher(
				for: NSNotification.Name.AuthStateDidChange,
				object: Auth.auth()
			)
			.debounce(for: 0.3, scheduler: RunLoop.main)
			.sink { [weak self] _ in
				guard let self else { return }
				self.handleAuthStateChange()
			}
			.store(in: cancelBag)
	}

	public func handleAuthStateChange() {
		authState = determineAuthState()
	}

	private func determineAuthState() -> AuthState {
		let storage = GroupAppStorage.shared
		guard let user = Auth.auth().currentUser else {
			storage.delete(for: .auth(.currentUserID))
			return .loggedOut
		}
		if storage.string(for: .auth(.currentUserID)) != user.uid {
			storage.save(value: user.uid, for: .auth(.currentUserID))
		}
		let currentUser = user.snapshot()
		return user.displayName == nil ? .newUser(user: currentUser) :
			.loggedIn(user: currentUser)
	}
}

public extension User {
	func snapshot() -> ContactSnapshot {
		return .init(
			uid: self.uid,
			name: self.displayName ?? "",
			mobile: self.phoneNumber ?? "",
			photoURL: self.photoURL?.absoluteString ?? "",
			pushToken: GroupAppStorage.shared
				.string(for: .device(.deviceToken)) ?? "",
			publicKeyString: GroupAppStorage.shared
				.string(for: .security(.publicKey(id: self.uid))) ?? ""
		)
	}
}
