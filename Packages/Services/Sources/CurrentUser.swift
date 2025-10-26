//
//  CurrentUser.swift
//
//  Created by Aung Ko Min on 2/7/24.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import XUI
import Core
import Database
import FirebaseMessaging

@MainActor
@Observable
public final class CurrentUser {

	public enum XError: Error {
		case notLoggedIn
		case noDeviceToken
	}

	public var user: Contact

	public init(_ snapshot: Contact) {
		user = snapshot
	}

	public func updateIfNeeded() async throws {
		let deviceToken = GroupAppStorage.shared.string(
			for: .device(.deviceToken)
		) ?? ""
		if GroupAppStorage.shared
			.string(for: .device(.deviceToken)) != deviceToken {
			GroupAppStorage.shared
				.save(value: deviceToken, for: .device(.deviceToken))
		}

		let publicKeyString = CryptoService.shared.publicKeyString
		user.pushToken = deviceToken
		user.publicKeyString = publicKeyString

		let remoteUser = try? await getRemoteUser()

		if user != remoteUser {
			try await setOnRemote()
		}
	}

	private func setOnRemote() async throws {
		let reference = Firestore.firestore().collection("users")
		try await reference
			.document(user.uid)
			.setData(user.dictionary, merge: true)
	}

	private func getRemoteUser() async throws -> Contact? {
		let query = Firestore
			.firestore()
			.collection("users")
			.whereField("uid", isEqualTo: user.uid)

		let model: Contact? = try await FirestoreRepo.fetchSingle(query: query)
		return model
	}
}

public extension CurrentUser {
	static var current: Contact? {
		guard let user = Auth.auth().currentUser else {
			return nil
		}
		return user.snapshot()
	}
}
