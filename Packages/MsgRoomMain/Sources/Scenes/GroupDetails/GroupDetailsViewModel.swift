//
//  GroupDetailsViewModel.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 24/8/25.
//

import Foundation
import Database
import Services
import FirebaseFirestore
import MediaPicker

@MainActor
@Observable
public final class GroupDetailsViewModel: ErrorPresenter {
	
	var conversation: ConversationSnapshot
	var contacts = [ContactSnapshot]()
	var originalGroup: ConversationSnapshot
	var pickedPhoto: PickedPhoto?
	var isLoading = false
	
	init(conversation: ConversationSnapshot) {
		self.conversation = conversation
		self.originalGroup = conversation
		contacts = conversation.members
			.compactMap{ ContactStore.shared.contact(for: $0) }
	}
	
	func setLoading(_ isLoading: Bool) {
		self.isLoading = isLoading
	}

	var hasChanges: Bool {
		conversation != originalGroup || pickedPhoto != nil || conversation.members.sorted() != contacts.map{ $0.uid }.sorted()
	}
	
	func reset() {
		conversation = originalGroup
		pickedPhoto = nil
		contacts = conversation.members
			.compactMap{ ContactStore.shared.contact(for: $0) }
	}
	
	func uploadImage(image: UIImage) async throws -> String {
		setLoading(true)
		UIApplication.shared.endEditing()
		let uid = originalGroup.uid
		let imageUploader = ImageUploadingService()
		let url = try await imageUploader.uploadImage(
			image,
			size: .init(width: 100, height: 100),
			to: .group(groupID: uid)
		)
		return url
	}
	func applyUpdate() async throws {
		setLoading(true)
		UIApplication.shared.endEditing()
		try await Task.sleep(seconds: 1)
		let group = self.conversation
		try await Store.shared.conversationStore
			.updateAndSave(uid: originalGroup.uid) { model in
				model.update(with: group)
			}
		try await FirestoreRepo
			.update(
				Group(snapshot: group),
				to: Firestore
					.firestore()
					.collection("groups")
					.document(group.uid)
			)
		setLoading(false)
	}
}
