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
public final class CurrentUser: Sendable {
	
	public enum XError: Error {
		case notLoggedIn
		case noDeviceToken
	}
	
	public var user: ContactSnapshot
	
	public init(_ snapshot: ContactSnapshot) {
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
	
	private func getRemoteUser() async throws -> ContactSnapshot {
		try await Firestore
			.firestore()
			.collection("users")
			.document(user.uid)
			.getDocument(as: ContactSnapshot.self)
	}
}
