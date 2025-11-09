//
//  AuthService.swift
//  Services
//
//  Created by Aung Ko Min on 21/5/25.
//

import Core
import Database
import FirebaseAuth
import FirebaseMessaging
import SwiftUI
import XUI

public enum AuthState {
	case loggedIn(_ user: User)
	case loggedOut
	case newUser(_ user: User)
	case initial, unknown
}

@MainActor
@Observable
public class AuthService {
	public init() {}

	public var authState: AuthState = .unknown
	private let cancelBag = CancelBag()

	public func start() {
		authState = determineAuthState()
		observeAuthState()
	}

	public func observeAuthState() {
		NotificationCenter.default
			.publisher(
				for: NSNotification.Name.AuthStateDidChange,
				object: Auth.auth()
			)
			.debounce(for: 1, scheduler: RunLoop.main)
			.sink { [weak self] _ in
				guard let self else { return }
				handleAuthStateChange()
			}
			.store(in: cancelBag)
	}

	private func handleAuthStateChange() {
		authState = determineAuthState()
	}

	private func handleLoggedIn(with user: User) -> AuthState {
		let storage = GroupStorage.shared
		storage.save(user.uid, for: .auth(.currentUserID))
		return user.displayName == nil ? .newUser(user) : .loggedIn(user)
	}

	private func handleLoggaedOut() -> AuthState {
		let storage = GroupStorage.shared
		if let currentUserID = storage.string(for: .auth(.currentUserID)) {
			storage.delete(for: .auth(.authToken))
			storage.delete(for: .device(.deviceToken))
			storage.delete(for: .security(.privateKey(id: currentUserID)))
		}
		return .loggedOut
	}

	private func determineAuthState() -> AuthState {
		if let user = Auth.auth().currentUser {
			return handleLoggedIn(with: user)
		}
		return handleLoggaedOut()
	}
}
