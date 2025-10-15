//
//  CreateGroupViewModel.swift
//  Bubbly
//
//  Created by Aung Ko Min on 20/8/25.
//

import SwiftUI
import Database
import XUI
import Services
import FirebaseFirestore
import MediaPicker

@MainActor
@Observable
final class CreateGroupViewModel: Sendable {

	var groupName: String = ""
	var selection = [ContactSnapshot]()
	var pickedPhoto: PickedPhoto?
	var uploadedURL: URL?
	var isLoading: Bool = false

	var canCreateGroup: Bool {
		!groupName.isEmpty && !selection.isEmpty && pickedPhoto != nil
	}

	func onSelect(contact: ContactSnapshot) {
		if let index = selection.firstIndex(where: { $0.uid == contact.uid }) {
			selection.remove(at: index)
		} else {
			selection.append(contact)
		}
	}

	func createGroup() async throws {
		guard let currentUserID = currentUserId, let image = pickedPhoto?.uiImage else {
			fatalError()
		}
		setLoading(true)
		let groupID = UUID().uuidString
		let imageUploader = ImageUploadingService()
		let url = try await imageUploader.uploadImage(
			image,
			size: .init(width: 100, height: 100),
			to: .group(groupID: groupID)
		)
		let memberIDs = [currentUserID] + selection.map { $0.uid }
		let group = Group(
			uid: groupID,
			name: groupName,
			createdDate: .init(.now),
			photoURL: url,
			members: memberIDs,
			createdBy: currentUserID
		)
		try await FirestoreRepo
			.add(
				group,
				to: Firestore.firestore().collection("groups").document(groupID)
			)
		try await Store.shared.conversationStore.insert(.init(group: group))
		try await Task.sleep(seconds: 2)
		setLoading(false)
	}

	@MainActor func setLoading(_ loading: Bool) {
		isLoading = loading
	}
}
