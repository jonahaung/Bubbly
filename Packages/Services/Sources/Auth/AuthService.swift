//
//  AuthService.swift
//  Services
//
//  Created by Aung Ko Min on 21/5/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseMessaging
import XUI
import Database
import Core

@MainActor
@Observable
public class AuthService {

	public enum AuthState {
		case loggedIn(_ user: User), loggedOut, newUser(_ user: User), initial, unknown
	}

	@MainActor
	public static let shared = AuthService()
	private init() {}

	public var authState: AuthState = .unknown
	@ObservationIgnored private let cancelBag = CancelBag()

	public func start() {
		authState = determineAuthState()
		observeAuthState()
		debugPrint("2️⃣ AuthService starting...")
	}

	public func observeAuthState() {
		NotificationCenter.default
			.publisher(
				for: NSNotification.Name.AuthStateDidChange,
				object: Auth.auth()
			)
			.subscribe(on: RunLoop.main)
			.sink { [weak self] _ in
				guard let self else { return }
				self.handleAuthStateChange()
			}
			.store(in: cancelBag)
		debugPrint("3️⃣ AuthService observeAuthState \(authState)")
	}
	private func handleAuthStateChange() {
		authState = determineAuthState()
	}
	private func handleLoggedIn(with user: User) -> AuthState {
		let storage = GroupAppStorage.shared
		if storage.string(for: .auth(.currentUserID)) != user.uid {
			storage.save(value: user.uid, for: .auth(.currentUserID))
		}
		return user.displayName == nil ? .newUser(user) : .loggedIn(user)
	}
	private func handleLoggaedOut() -> AuthState {
		let storage = GroupAppStorage.shared
		storage.delete(for: .auth(.currentUserID))
		storage.delete(for: .auth(.authToken))
		storage.delete(for: .device(.deviceToken))
		return .loggedOut
	}
	private func determineAuthState() -> AuthState {
		if let user = Auth.auth().currentUser {
			return handleLoggedIn(with: user)
		}
		return handleLoggaedOut()
	}
}
